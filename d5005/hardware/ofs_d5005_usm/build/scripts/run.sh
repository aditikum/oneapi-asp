#!/bin/bash

# Copyright 2020 Intel Corporation.
#
# THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
# COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if [ -n "$OFS_OCL_ENV_DEBUG_SCRIPTS" ]; then
  set -x
fi

echo "This is the OFS HLD shim BSP run.sh script."

# set BSP flow
if [ $# -eq 0 ]
then
    BSP_FLOW="flat"
else
    BSP_FLOW="$1"
fi
echo "Compiling '$BSP_FLOW' bsp-flow"

SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
echo "OFS BSP run.sh script path: $SCRIPT_PATH"

SCRIPT_DIR_PATH="$(dirname "$SCRIPT_PATH")"
echo "OFS BSP build dir: $SCRIPT_DIR_PATH"

#if flow-type is 'flat_kclk' uncomment USE_KERNEL_CLK_EVERYWHERE_IN_PR_REGION in opencl_bsp.vh
if [ ${BSP_FLOW} = "afu_flat_kclk" ]; then
    echo "Enabling the USE_KERNEL_CLK_EVERYWHERE_IN_PR_REGION define in the Shim RTL..."
    SHIM_HEADER_FILE_NAME="${SCRIPT_DIR_PATH}/../rtl/opencl_bsp.vh"
    echo "Modifying the header file ${SHIM_HEADER_FILE_NAME} to uncomment the define and include it in the design."
    sed -i -e 's/\/\/`define USE_KERNEL_CLK_EVERYWHERE_IN_PR_REGION/`define USE_KERNEL_CLK_EVERYWHERE_IN_PR_REGION/' "$SHIM_HEADER_FILE_NAME"
    BSP_FLOW="afu_flat"
fi

PYTHONPATH="$OFS_OCL_SHIM_ROOT/build/opae/install/lib/python3.7/site-packages"

cd "$SCRIPT_DIR_PATH/.." || exit

if [[ -n "$OFS_OCL_ENV_USE_BSP_PACKAGER" || -n "$ARC_SITE" ]]; then
  if [ -f ./tools/packager ]; then
    chmod +x ./tools/packager
    PACKAGER_BIN=$(readlink -f ./tools/packager)
  else
    echo "Error cannot find BSP copy of packager"
    exit 1
  fi
else
  if ! PACKAGER_BIN=$(which packager); then
    echo "Error: cannot find packager in path"
    exit 1
  fi
fi

if ! PACKAGER_OUTPUT=$($PACKAGER_BIN); then
    echo "ERROR: packager ($PACKAGER_BIN) check failed with output '$PACKAGER_OUTPUT'"
    exit 1
fi

##make sure bbs files exist
if [ ! -f "d5005.qdb" ]; then
    echo "ERROR: BSP is not setup"
fi

cp ../quartus.ini .

#import opencl kernel files
quartus_sh -t scripts/import_opencl_kernel.tcl

#check for bypass/alternative flows
if [ -n "$OFS_OCL_ENV_ENABLE_ASE" ]; then
    echo "Calling ASE simulation flow compile"
    sh ./scripts/ase-sim-compile.sh
    exit $?
fi

#add BBBs to quartus pr project
quartus_sh -t scripts/add_bbb_to_pr_project.tcl "$BSP_FLOW"

cp ../afu_opencl_kernel.qsf .

#get a list of gsys files that are mentioned in qsf files; then generate each of them
eval "$(grep "QSYS_FILE" afu_flat.qsf | grep -v "^#" > qsys_filelist.txt)"

while read -r line; do
    f=$(echo "$line" | awk '{print $4}')
    qsys-generate -syn --quartus-project=d5005 --rev=afu_opencl_kernel "$f"
    # adding board.qsys and corresponding .ip parameterization files to opencl_bsp_ip.qsf
    qsys-archive --quartus-project=d5005 --rev=afu_opencl_kernel --add-to-project "$f"
done < qsys_filelist.txt

rm -rf qsys_filelist.txt

qsys-generate -syn --quartus-project=d5005 --rev=afu_opencl_kernel board.qsys
# adding board.qsys and corresponding .ip parameterization files to opencl_bsp_ip.qsf
qsys-archive --quartus-project=d5005 --rev=afu_opencl_kernel --add-to-project board.qsys

#append kernel_system qsys/ip assignments to all revisions
rm -f kernel_system_qsf_append.txt
{ echo
  grep -A10000 OPENCL_KERNEL_ASSIGNMENTS_START_HERE afu_opencl_kernel.qsf
  echo
} >> kernel_system_qsf_append.txt

cat kernel_system_qsf_append.txt >> afu_flat.qsf

# compile project
# =====================
quartus_sh -t scripts/compile_script.tcl "$BSP_FLOW"
FLOW_SUCCESS=$?

# Report Timing
# =============
if [ $FLOW_SUCCESS -eq 0 ]
then
    quartus_sh -t scripts/adjust_plls.tcl d5005 afu_"${BSP_FLOW}"
else
    echo "ERROR: kernel compilation failed. Please see quartus_sh_compile.log for more information."
    exit 1
fi

#run packager tool to create GBS
BBS_ID_FILE="fme-ifc-id.txt"
if [ -f "$BBS_ID_FILE" ]; then
    FME_IFC_ID=$(cat $BBS_ID_FILE)
else
    echo "ERROR: fme id not found."
    exit 1
fi

PLL_METADATA_FILE="pll_metadata.txt"
if [ -f "$PLL_METADATA_FILE" ]; then
    IFS=" " read -r -a PLL_METADATA <<< "$(cat $PLL_METADATA_FILE)"
else
    echo "Error: cannot find $PLL_METADATA_FILE"
    exit 1
fi

#check for generated rbf and gbs files
if [ ! -f "./output_files/afu_${BSP_FLOW}.persona1.rbf" ]; then
    echo "ERROR: ./output_files/afu_${BSP_FLOW}.persona1.rbf is missing!"
    exit 1
fi

rm -f afu.gbs
$PACKAGER_BIN create-gbs \
    --rbf "./output_files/afu_${BSP_FLOW}.persona1.rbf" \
    --gbs "./output_files/afu_${BSP_FLOW}.gbs" \
    --afu-json opencl_afu.json \
    --set-value \
        interface-uuid:"$FME_IFC_ID" \
        "${PLL_METADATA[@]}"

FLOW_SUCCESS=$?
if [ $FLOW_SUCCESS != 0 ]; then
    echo "ERROR: packager tool failed to create .gbs file."
    exit 1
fi

rm -rf fpga.bin

gzip -9c ./output_files/afu_"${BSP_FLOW}".gbs > afu_"${BSP_FLOW}".gbs.gz
aocl binedit fpga.bin create
aocl binedit fpga.bin add .acl.gbs.gz "./afu_${BSP_FLOW}.gbs.gz"

echo "run.sh: done zipping up the gbs into gbs.gz, and creating fpga.bin"

if [ -f "afu_${BSP_FLOW}.failing_clocks.rpt" ]; then
    aocl binedit fpga.bin add .failing_clocks.rpt "./afu_${BSP_FLOW}.failing_clocks.rpt"
    cp "./afu_${BSP_FLOW}.failing_clocks.rpt" ../
    echo "run.sh: done appending failing clocks report to fpga.bin"
fi

if [ -f "afu_${BSP_FLOW}.failing_paths.rpt" ]; then
    aocl binedit fpga.bin add .failing_paths.rpt "./afu_${BSP_FLOW}.failing_paths.rpt"
    cp "./afu_${BSP_FLOW}.failing_paths.rpt" ../
    echo "run.sh: done appending failing paths report to fpga.bin"
fi

if [ ! -f fpga.bin ]; then
    echo "ERROR: no fpga.bin found.  FPGA compilation failed!"
    exit 1
fi

#copy fpga.bin to parent directory so aoc flow can find it
cp fpga.bin ../
cp acl_quartus_report.txt ../

echo ""
echo "==========================================================================="
echo "OpenCL AFU compilation complete"
echo "==========================================================================="
echo ""