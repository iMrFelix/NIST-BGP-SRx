#!/bin/bash
# This script is auto-generated by BGP-SRx Software Suite Bundler V5.6

# Date: Fri Sep  3 22:58:01 EDT 2021
# CMD: /bin/get-BGPSRx -S -i BGP-SRx-Latest --latest5

SCRIPTNAME='BGP-SRx Software Suite V5.1.8 Build script V5.6!'
# Check the parameter $1, if 0 OK if 1 display error $2 and exit

# The prefix directory where everything gets installed in
if [ "$(dirname $0)" == "$(pwd)" ] ; then
  INSTALL_DIR="$(dirname $0)"
else
  INSTALL_DIR="$(pwd)/$(dirname $0)"
fi

# This is used for the configuration call
LOC_PREFIX=$(echo $INSTALL_DIR/local-5.1.8 | sed -e "s/\/\.\//\//g")

# This is used for the .vscode json files.
REL_LOC_PREFIX="local-5.1.8"

# This variable specifies a file that will be generated when a custom
# binary install location is specified with -P
# If this file exists, the parameters LOC_PREF and REL_LOC_PREF will
# be overwritten with the values stored. This is usefull for consecutive
# calls of the build script. To remove the file use the parameter -PR
PREFIX_PARAM_FILE=$INSTALL_DIR/bgp-srx-build.param

# Specifies if the above file is to be "use"d, "delete"ed, pr "create"d!
# It also can be empty if "use" but no file is available. This is important
# for the vscode json scripts.
PREFIX_PARAM="use"

DO_CONFIGURE=1
DO_MAKE=1
DO_INSTALL=1
DO_DISTCLEAN=0
DO_UPDATE=0

ERR_OFFSET=0
ERR_OFFSET_SCA=10
ERR_OFFSET_SRxSnP=20
ERR_OFFSET_QSRx=30
ERR_OFFSET_BIO=40
ERR_OFFSET_EXAMPLES=50

DO_TOUCH_AUTOMAKE=0
DO_VSCODE=0

RUN_TEST=0

# Initialize AUTOMATED as empty parameter.
AUTOMATED=

DO_SCA=0
DO_SRxSnP=0
DO_QSRx=0
DO_BIO=0
DO_EXAMPLES=0

PARAM_SCA=""
PARAM_SRxSnP=""
PARAM_QSRX=""
PARAM_BIO=""
PARAM_EXAMPLES=""
CRS_USER=""
CRS_PASSWORD=""
CRS_CMD="git"

function exit_script()
{
  EXIT_CODE=0
  if [ "$1" != "" ] ; then
    EXIT_CODE=$1
    if [ "$2" != "" ] ; then
      EXIT_CODE=$(($1 + $2))
    fi
  fi
  echo $SCRIPTNAME
  echo "2017/2021 by Oliver Borchert (NIST)"
  echo
  exit $EXIT_CODE
}

function doTest()
{
  local retVal_sca=0
  local retval_bio_sca=0
  if [ ! -e $LOC_PREFIX/opt/bgp-srx-examples/test-sca/ ] ; then
    echo
    echo "First compile and install the framework prior testing!"
    echo
    exit 1
  fi
  pushd . >> /dev/null
  cd $LOC_PREFIX/opt/bgp-srx-examples/test-sca/
  echo "Run test-sca..."
  testruns=( 1 2 3 )
  for testrun in ${testruns[@]} ; do
    echo -n "  Test sca-$testrun: "
    ./run.sh sca-$testrun --report
    retVal_sca=$(($retVal_sca+$?))
  done
  popd >> /dev/null

  pushd . >> /dev/null
  cd $LOC_PREFIX/opt/bgp-srx-examples/test-bio-sca/
  echo "Run  test-bio-sca..."
  testruns=( 1 2 )
  for testrun in ${testruns[@]} ; do
    echo -n "  Test bio-sca-$testrun: "
    ./run.sh bio-sca-$testrun --report
    retVal_bio_sca=$(($retVal_bio_sca+$?))
  done
  popd >> /dev/null


  retVal=$(($retVal_sca+$retval_bio_sca))
  if [ $retVal -eq 0 ] ; then
    echo "All tests were successful!"
  else
    echo "$retVal_sca tests \"test-sca\" failed!!"
    echo "$retval_bio_sca tests \"test-bio-sca\" failed!!"
  fi
  exit $retVal
}

function createVsCode()
{
  #Determine direcotries:
  local ROOT_SCA=$( ls | grep srx-crypto-api )
  local ROOT_SRxSnP=$( ls | grep srx-server )
  local ROOT_QSRx=$( ls | grep quagga-srx )
  local ROOT_BIO=$( ls | grep bgpsec-io )

  if [ -e .vscode ] ; then
  echo "Virtual Studio Code Project folder already exists."
    echo "Abort generation."
    return
  fi

  local f_tasks=".vscode/tasks.json"
  local f_launch=".vscode/launch.json"
  local f_c_cpp_properties=".vscode/c_cpp_properties.json"
  local packages=()
  local firstConfig=1
  local idx=0

  mkdir .vscode

  if [ $DO_SCA -eq 1 ] ; then
    packages+=("SCA")
##              Label        # Source  # Program             [# param1 # param 2 #....# param n]
##   The hash "#" symbol will be replaced with space " " later on.
    debugger+=("Crypro-Tester#$ROOT_SCA#sbin/srx_crypto_tester")
  fi
  if [ $DO_SRxSnP -eq 1 ] ; then
    packages+=("SRxSnP")
##              Label     # Source         # Program      [# param1 # param 2 #....# param n]
    debugger+=("SRx-Server#$ROOT_SRxSnP/src#bin/srx_server#-f#../etc/srx_server.conf")
    debugger+=("RPKI-Router-Server#$ROOT_SRxSnP/src#bin/rpkirtr_svr#50000#-f#../etc/cache.conf")
    debugger+=("SRx-Server-Client#$ROOT_SRxSnP/src#bin/srx_svr_client")
    debugger+=("RPKI-Router-Server-Client#$ROOT_SRxSnP/src#bin/rpkirtr_client")
  fi
  if [ $DO_QSRx -eq 1 ] ; then
    packages+=("QSRx")
    debugger+=("Quagga-SRx#$ROOT_QSRx/bgpd#sbin/bgpd#-f#../etc/bgpd.conf|miDebuggerServerAddress=localhost:2900|miDebuggerPath=/usr/bin/gdb")
  fi
  if [ $DO_BIO -eq 1 ] ; then
    packages+=("BIO")
    debugger+=("BGPsrx-IO#$ROOT_BIO#bin/bgpsecio#-f#../etc/bio-demo.cfg")
  fi

  local mode=("-B" "-C" "-M" "-I" "-D")
  # Generate the tasks.json
  echo "{" >> $f_tasks
  echo "  \"tasks\": [" >> $f_tasks
  echo "    {" >> $f_tasks
  echo "      \"type\": \"shell\"," >> $f_tasks
  echo "      \"label\": \"Build BGP-SRx (${packages[@]})\"," >> $f_tasks
  echo "      \"command\": \"\${workspaceFolder}/buildBGP-SRxtrunk.sh\"," >> $f_tasks

  local args=(${packages[@]} "-A")
  if [ $DO_TOUCH_AUTOMAKE -eq 1 ] ; then
    args+=("-T")
  fi

  firstConfig=1
  idx=1
  for arg in ${args[@]}
  do
    if [ $firstConfig -eq 1 ] ; then
      if [ ${#args[@]} -eq 1 ] ; then
        echo "      \"args\": [\"$arg\"], " >> $f_tasks
      else
        echo "      \"args\": [\"$arg\"," >> $f_tasks
        firstConfig=0
      fi
    else
      if [ $idx -eq ${#args[@]} ] ; then
        echo "               \"$arg\"]," >> $f_tasks
      else
        echo "               \"$arg\", " >> $f_tasks
      fi
    fi
    idx=$(($idx + 1))
  done

  echo "      \"options\": { \"cwd\": \"\${workspaceFolder}\" }," >> $f_tasks
  echo "      \"group\": { \"kind\": \"build\", \"isDefault\": true}," >> $f_tasks
  echo "      \"problemMatcher\": [\"\$gcc\"]" >> $f_tasks
  echo "    }" >> $f_tasks
  for v_mode in ${mode[@]}
  do
    for package in ${packages[@]}
    do
      task_group="\"none\""
      task_command="$v_mode"
      case "$v_mode" in
        "-C") pkg_label="Configure" ;;
        "-B") pkg_label="Build"
              task_group="{ \"kind\": \"build\", \"isDefault\": true }" ;;
        "-M") pkg_label="Make" 
              task_group="{ \"kind\": \"test\", \"isDefault\": true }" ;;
        "-I") pkg_label="Install" ;;
        "-D") pkg_label="Clean" ;;
        *) echo "Error: Invalid task type"; exit_script 1 ;;
      esac
      echo "    ,{" >> $f_tasks
      echo "      \"type\": \"shell\"," >> $f_tasks
      echo "      \"label\": \""$package $pkg_label"\"," >> $f_tasks
      echo "      \"command\": \"\${workspaceFolder}/buildBGP-SRxtrunk.sh\"," >> $f_tasks
      echo "      \"args\": [\"$package\", " >> $f_tasks
      if [ $DO_TOUCH_AUTOMAKE -eq 1 ] ; then
        echo "               \"-T\"," >> $f_tasks
      fi
      echo "               \"$task_command\"," >> $f_tasks
      echo "               \"-A\"]," >> $f_tasks
      echo "      \"options\": { \"cwd\": \"\${workspaceFolder}\" }," >> $f_tasks
      echo "      \"group\": $task_group," >> $f_tasks
      echo "      \"problemMatcher\": [\"\$gcc\"]" >> $f_tasks
      echo "    }" >> $f_tasks
    done
  done
  echo "  ]" >> $f_tasks
  echo "}" >> $f_tasks

  # Generate the launch.json
  echo "{" >> $f_launch
  echo "  // Use IntelliSense to learn about possible attributes." >> $f_launch
  echo "  // Hover to view descriptions of existing attributes." >> $f_launch
  echo "  // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387" >> $f_launch
  echo "  \"version\": \"0.2.0\"," >> $f_launch
  local firstConfig=1
  echo "  \"configurations\": [" >> $f_launch
  for debug in ${debugger[@]}
  do
    if [ $firstConfig -eq 1 ] ; then
      echo "    {" >> $f_launch
      firstConfig=0
    else
      echo "    , {" >> $f_launch
    fi
    local debugSection=($(echo $debug | sed -e "s/|/ /g"))
    # The first part is the normal debug, all following ones are
    # additional optional parameters.
    debug=$debugSection
    local moreParameters=()
    for section in ${debugSection[@]}
    do
      if [ "$section" != "$debug" ] ; then
        moreParameters+=( $section )
      fi
    done
    local debugData=($(echo $debug | sed -e "s/#/ /g"))
    echo "      \"name\": \"(gdb) Launch ${debugData[0]}\"," >> $f_launch
    echo "      \"type\": \"cppdbg\"," >> $f_launch
    echo "      \"request\": \"launch\"," >> $f_launch
    if [ "$PREFIX_PARAM" == "" ] ; then
      echo "      \"program\": \"\${workspaceFolder}/$REL_LOC_PREFIX/${debugData[2]}\"," >> $f_launch
    else
      echo "      \"program\": \"$REL_LOC_PREFIX/${debugData[2]}\"," >> $f_launch
    fi
    local param=()
    if [ ${#debugData[@]} -gt 3 ] ; then
      echo "      \"args\": [" >> $f_launch
      local idx=3
      while [ $idx -lt ${#debugData[@]} ] ; do
        if [ $idx -eq 3 ] ; then
          echo "               \"${debugData[$idx]}\"" >> $f_launch
        else
          echo "               ,\"${debugData[$idx]}\"" >> $f_launch
        fi
        idx=$(($idx + 1))
      done
      echo "              ]," >> $f_launch
    else
      echo "      \"args\": [\"\"]," >> $f_launch
    fi
    echo "      \"stopAtEntry\": true," >> $f_launch
    echo "      \"cwd\": \"\${workspaceFolder}/${debugData[1]}\"," >> $f_launch
    echo "      \"environment\": []," >> $f_launch
    echo "      \"externalConsole\": false," >> $f_launch
    echo "      \"MIMode\": \"gdb\"," >> $f_launch
    for newParam in ${moreParameters[@]}
    do
      local pSplit=($( echo $newParam | sed -e "s/=/ /g" ))
      echo "      \"${pSplit[0]}\": \"${pSplit[1]}\"," >> $f_launch
    done
    echo "      \"setupCommands\": [" >> $f_launch
    echo "        {" >> $f_launch
    echo "          \"description\": \"Enable pretty-printing for gdb\"," >> $f_launch
    echo "          \"text\": \"-enable-pretty-printing\"," >> $f_launch
    echo "          \"ignoreFailures\": true" >> $f_launch
    echo "        }" >> $f_launch
    echo "      ]" >> $f_launch
    echo "    }" >> $f_launch
  done
    echo "  ]" >> $f_launch
    echo "}" >> $f_launch

  # Generate the c_cpp_properties.json for IntelliSense
  echo "{" >> $f_c_cpp_properties
  echo "    \"env\": {" >> $f_c_cpp_properties
  if [ "$PREFIX_PARAM" == "" ] ; then
    echo "        \"SRxIncludePath\": \"\${workspaceFolder}/$REL_LOC_PREFIX/include\"," >> $f_c_cpp_properties
  else
    echo "        \"SRxIncludePath\": \"$REL_LOC_PREFIX/include\"," >> $f_c_cpp_properties
  fi
  if [ $DO_SCA -eq 1 ] ; then
    echo "        \"SCAIncludePath\": \"\${workspaceFolder}/$ROOT_SCA\"," >> $f_c_cpp_properties
  fi
  if [ $DO_SRxSnP -eq 1 ] ; then
    echo "        \"SRxSnPIncludePath\": [ " >> $f_c_cpp_properties
    echo "            \"\${workspaceFolder}/$ROOT_SRxSnP/extras/local/include\"," >> $f_c_cpp_properties
    echo "            \"\${workspaceFolder}/$ROOT_SRxSnP/src\"" >> $f_c_cpp_properties
    echo "        ]," >> $f_c_cpp_properties
  fi
  if [ $DO_QSRx -eq 1 ] ; then
    echo "        \"QSRxIncludePath\": [ " >> $f_c_cpp_properties
    if [ "$PREFIX_PARAM" == "" ] ; then
      echo "            \"\${workspaceFolder}/$REL_LOC_PREFIX/include/quaggasrx\"," >> $f_c_cpp_properties
      echo "            \"\${workspaceFolder}/$REL_LOC_PREFIX/include/srx\"," >> $f_c_cpp_properties
    else
      echo "            \"$REL_LOC_PREFIX/include/quaggasrx\"," >> $f_c_cpp_properties
      echo "            \"$REL_LOC_PREFIX/include/srx\"," >> $f_c_cpp_properties
    fi
    echo "            \"\${workspaceFolder}/$ROOT_QSRx/lib\"," >> $f_c_cpp_properties
    echo "            \"\${workspaceFolder}/$ROOT_QSRx\"" >> $f_c_cpp_properties
    echo "        ]," >> $f_c_cpp_properties
  fi
  if [ $DO_BIO -eq 1 ] ; then
    echo "        \"BIOIncludePath\": \"\${workspaceFolder}/$ROOT_BIO\"," >> $f_c_cpp_properties
  fi
  echo "        \"SRX_DEFINES\": [ \"USE_SRX\" ]" >> $f_c_cpp_properties
  echo "    }," >> $f_c_cpp_properties
  echo "    \"configurations\": [" >> $f_c_cpp_properties
  echo "        {" >> $f_c_cpp_properties
  echo "          \"includePath\": [" >> $f_c_cpp_properties
  if [ $DO_SCA -eq 1 ] ; then
    echo "              \"\${SCAIncludePath}\"," >> $f_c_cpp_properties
  fi
  if [ $DO_SRxSnP -eq 1 ] ; then
    echo "              \"\${SRxSnPIncludePath}\"," >> $f_c_cpp_properties
  fi
  if [ $DO_QSRx -eq 1 ] ; then
    echo "              \"\${QSRxIncludePath}\"," >> $f_c_cpp_properties
  fi
  if [ $DO_BIO -eq 1 ] ; then
    echo "              \"\${BIOIncludePath}\"," >> $f_c_cpp_properties
  fi
  echo "              \"\${SRxIncludePath}\"" >> $f_c_cpp_properties
  echo "          ]," >> $f_c_cpp_properties
  echo "          \"defines\": [" >> $f_c_cpp_properties
  echo "                \"ADD_PROJECT_RELATED_DEFINES_HERE\"," >> $f_c_cpp_properties
  echo "                \"\${SRX_DEFINES}\"" >> $f_c_cpp_properties
  echo "          ]," >> $f_c_cpp_properties
  echo "          \"browse\": {" >> $f_c_cpp_properties
  echo "              \"path\": [" >> $f_c_cpp_properties
  echo "                  \"${workspaceFolder}\"" >> $f_c_cpp_properties
  echo "              ]," >> $f_c_cpp_properties
  echo "              \"limitSymbolsToIncludedHeaders\": true," >> $f_c_cpp_properties
  echo "              \"databaseFilename\": \"\"" >> $f_c_cpp_properties
  echo "          }," >> $f_c_cpp_properties
  echo "          \"name\": \"Linux\"" >> $f_c_cpp_properties
  echo "        }" >> $f_c_cpp_properties
  echo "    ]," >> $f_c_cpp_properties
  echo "    \"version\": 4" >> $f_c_cpp_properties
  echo "}" >> $f_c_cpp_properties
  echo "To start remote debugging call:"
  echo "     sudo gdbserver localhost:2900 bgpd -f <config-file> "
  echo "Then star the QSRx debug session."
}

function touch_automake()
{
  echo "Run touch on Makefile framework!"
  # A fix to prevent the error message
  # WARNING: aclocal-1.13 is missing on your system.

  # get all files of the Makefile framework, then use the timestamp of the
  # first file and apply it to all.

  local t_installs=(DO_SCA=$DO_SCA DO_SRxSnP=$DO_SRxSnP DO_QSRx=$DO_QSRx DO_BIO=$DO_BIO)
  local t_folders=()
  for t_inst in ${t_installs[@]}
  do
    case "$t_inst" in
      "DO_SCA=1")    t_folders+=($(ls | grep srx-crypto-api*)) ;;
      "DO_SRxSnP=1") t_folders+=($(ls | grep srx-server*)) ;;
      "DO_QSRx=1")   t_folders+=($(ls | grep quagga-srx*)) ;;
      "DO_BIO=1")    t_folders+=($(ls | grep bgpsec-io*)) ;;
      *) ;;
    esac
  done
  for t_folder in ${t_folders[@]}
  do
    if [ -e $t_folder ] ; then
      echo "  - Perform [touch] on Makefile Framework in folder [$t_folder]"
      pushd . > /dev/null
      cd $t_folder
      local framework=($(find | grep ".*\.m4$\|configure[\.ac\]*$\|Makefile\.am$\|Makefile\.in$\|config\.h\.in$"))
      local tsFile=$framework
      for fileName in ${framework[@]}
      do
        echo "    * touch -r $tsFile $fileName"
        touch -r $tsFile $fileName > /dev/null 2>&1
      done
      popd > /dev/null
    else
      echo "WARNING: Could not find folder $t_folder to perform [touch]"
    fi
  done
}

function svn_credentials()
{
  read -p "SVN Username ($(whoami)): " CRS_USER
  if [ "$CRS_USER" == "" ] ; then
    CRS_USER=$(whoami)
  fi
  CRS_CMD="svn --no-auth-cache --username=$CRS_USER"

  read -sp "Password for $CRS_USER: " CRS_PASSWORD
  if [ "$CRS_PASSWORD" != "" ] ; then
    CRS_CMD="$CRS_CMD --password=$CRS_PASSWORD --non-interactive"
  fi
  echo
}

function disclaimer()
{
  local YN=$1
  local COUNT=0
  echo "This script is provided as a helper for building the BGP-SRx Software Suite."
  echo "We thoroughly tested this script but still, you use this script at your own risk."
  while [ "$YN" == "" ] ; do
    read -p "Do you want to continue? [Y/N] " YN
    case $YN in
      [Yy] ) ;;
      [Nn] ) exit_script ;;
      *)
        COUNT=$(($COUNT + 1))
        YN="" ;;
    esac
    if [ $COUNT -eq 3 ] ; then
      exit_script;
    fi
  done
}

# Print the syntax and exit
function syntax()
{
  echo
  echo "Syntax: $0 [SCA] [SRxSnP] [QSRx] [BIO] [EXAMPLES] [-A] [-T] [-C|-M|-B|-I|-D|-V|-R]"
  echo
  echo "  Module selection: If none are specified, build all"
  echo "    SCA:      Build SRx Crypro API"
  echo "    SRxSnP:   Build SRx Server and Proxy"
  echo "    QSRx:     Build Quagga SRx"
  echo "    BIO:      Build BGPSEC-IO"
  echo "    EXAMPLES: Install BGP-SRx examples and demo-keys"
  echo "              Works only in combination with default build mode"
  echo "              or the options -B, -I, -D, and -C"
  echo
  echo "  Build MODE: If none is specified, call ./configure ...; make; make install"
  echo "    -C   Configure only (./configure ...)"
  echo "    -M   Compile only   (make)"
  echo "    -B   Build          (make; make install)"
  echo "    -I   Install only   (make install)"
  echo "    -D   Cleanup only   (make uninstall; make distclean)"
  echo "                        This will also perform a removal of the parameter file"
  echo "                        $PREFIX_PARAM_FILE if it exists."
  echo "    -R   Run Tests only - The project must be compiled and installed"
  echo "         or the tests can not be run!"
  echo "    -V   Create .vscode folder for Virstual Studio Code integration."
  echo "         The provided .json scripts will provide tasks and launchers for"
  echo "         compiling and debuging the software modules. This switch only"
  echo "         installs a .vscode folder if it not already exists."
  echo "    -P <prefix>, --prefix <prefix>"
  echo "         This switch allows to specify the folder where the compiled binaries"
  echo "         and scripts will be installed in (--prefix=<prefix-dir>). If not "
  echo "         specified the installation directory is within the sandbox where "
  echo "         the source is installed in."
  echo "         This parameter will create the file $PREFIX_PARAM_FILE and store"
  echo "         the parameters LOC_PREFIX and REL_LOC_PREFIX for future use."
  echo "         To remove the file call with -PR."
  echo "    -PR  Remove a previous created file $PREFIX_PARAM_FILE."
  echo "    -X <sca|srxsnb|sca|bio|examples> <num> <parameter>*"
  echo "         Allow to pass additional parameters to the configuration calls."
  echo "         num reprresents the number of parameters to be processed here (0..n)!"
  echo "         * Do not use this parameter to add --prefix. Use -P for that instead."
  echo
  echo "  Optional Switch:"
  echo "    -A   Run the script automated (Disclaimer is answered [Y])"
  echo "    -T   Run [touch -r <f1> <f2>] on Makefile framework in case automake/autoconf"
  echo "         is required but not available! DO NOT USE if Makefile framework is modified!"
  echo
  exit_script
}

# check is all needs to be build or just portions
function checkParam()
{
  local DO_ALL=1
  local xLabel=""
  local xParamCt=0
  local xPos=0
  local xList=()

  while [ "$1" != "" ] ; do
    case $1 in
      "SCA") DO_SCA=1; DO_ALL=0 ;;
      "SRxSnP") DO_SRxSnP=1; DO_ALL=0 ;;
      "QSRx") DO_QSRx=1; DO_ALL=0 ;;
      "BIO") DO_BIO=1; DO_ALL=0 ;;
      "EXAMPLES") DO_EXAMPLES=1; DO_ALL=0 ;;
      "-A") AUTOMATED="Y" ;;
      "-B")
           # Only "make" and "make install"
           DO_CONFIGURE=0
           DO_MAKE=1
           DO_INSTALL=1
           DO_DISTCLEAN=0
           DO_UPDATE=0
           ;;
      "-M")
           # Only "make" and "make install"
           DO_CONFIGURE=0
           DO_MAKE=1
           DO_INSTALL=0
           DO_DISTCLEAN=0
           DO_UPDATE=0
           ;;
      "-C")
           # Only "./configure ..."
           DO_CONFIGURE=1
           DO_MAKE=0
           DO_INSTALL=0
           DO_DISTCLEAN=0
           DO_UPDATE=0
           ;;
      "-I")
           # Only "make install"
           DO_CONFIGURE=0
           DO_MAKE=0
           DO_INSTALL=1
           DO_DISTCLEAN=0
           DO_UPDATE=0
           ;;
      "-D")
           # Only "make distclean"
           DO_CONFIGURE=0
           DO_MAKE=0
           DO_INSTALL=0
           DO_DISTCLEAN=1
           DO_UPDATE=0
           PREFIX_PARAM="delete"
           ;;
      "-U")
           # Only "svn update"
           DO_CONFIGURE=0
           DO_MAKE=0
           DO_INSTALL=0
           DO_DISTCLEAN=0
           DO_UPDATE=1
           ;;
      "-T")
           # A fix to prevent an error in case automake and autoconf is not
           # installed.
           AUTO_TOOLS=(automake autoconf autoreconf)
           AUTOMKE=0
           for tool in ${AUTO_TOOLS[@]}
           do
             which $tool > /dev/null 2>&1
             AUTOMAKE=$(($AUTOMAKE + $?))
           done
           if [ $AUTOMAKE -gt 0 ] ; then
             DO_TOUCH_AUTOMAKE=1
           else
             echo "Makefile Framework installed - skip touch."
           fi
           ;;
      "-R")
           # Only "run tests"
           DO_CONFIGURE=0
           DO_MAKE=0
           DO_INSTALL=0
           DO_DISTCLEAN=0
           DO_UPDATE=0
           RUN_TEST=1
           AUTOMATED="Y"
           ;;
      "-V")
           DO_VSCODE=1
           DO_CONFIGURE=0
           DO_MAKE=0
           DO_INSTALL=0
           DO_DISTCLEAN=0
           DO_UPDATE=0
           ;;
      "-U")
           DO_VSCODE=0
           DO_CONFIGURE=0
           DO_MAKE=0
           DO_INSTALL=0
           DO_DISTCLEAN=0
           DO_UPDATE=1
           ;;
      "-P" | "--prefix")
           if [ "$2" == "" ] ; then
             echo "Parameter for $1 missing!"
             exit_script 1
           fi
           shift
           LOC_PREFIX=$(echo $1 | sed -e "s/\/\.\//\//g")
           REL_LOC_PREFIX=$LOC_PREFIX
           PREFIX_PARAM="create"
           ;;
      "-PR")
           PREFIX_PARAM="delete"
           ;;
      "-X")
           shift
           xLabel=$1
           shift
           xParamCt=$1
           xPos=0
           xList=()
           while [ $xPos -lt $xParamCt ] ; do
             shift
             xList+=( $1 )
             xPos=$(( $xPos+1 ))
           done
           case $xLabel in
             "sca")
                  PARAM_SCA=( ${xList[@]} )
                  ;;
             "srxsnp")
                  PARAM_SRxSnP=( ${xList[@]} )
                  ;;
             "qsrx")
                  PARAM_QSRx=( ${xList[@]} )
                  ;;
             "bio")
                  PARAM_BIO=( ${xList[@]} )
                  ;;
             "examples")
                  PARAM_EXAMPLES=( ${xList[@]} )
                  ;;
             *) echo "Incorrect parameter [$1]"; syntax ;;
           esac
           ;;
      "-?" | "h" | *) syntax ;;
    esac
    shift
  done

  if [ $DO_ALL -eq 1 ] ; then
    DO_SCA=1
    DO_SRxSnP=1
    DO_QSRx=1
    DO_BIO=1
    DO_EXAMPLES=1
  fi
}

# Check if the configure script exist, if not it generates one.
# If it cannot generate the configure script, it aborts the script with an error
function checkConfig()
{
  # lookup all configure.ac files
  local cfg_ac=($(find | grep configure.ac | sed -e "s/\(.\)configure.ac/\1/g" ))
  for cfg in ${cfg_ac[@]} 
  do 
    if [ ! -e "$cfg"configure ] ; then 
      which autoreconf > /dev/null
      if [ ! $? -eq 0 ] ; then
        echo "ERROR: autoconfig is required to build the configuration script - abort!"
        exit 1
      fi  
      pushd . ; cd $cfg
      autoreconf -i --force
      if [ -e autom4te.cache ] ; then
        rm -rf autom4te.cache
      fi
      popd
    fi 
  done
}

# Exit the shell if $1 is not 0. In this case $2 will be used as exit message.
# and $1 plus any value stored in ERR_OFFSET as exit code.
function check()
{
  local errCode=$1
  shift
  if [ "$errCode" != "0" ] ; then
    echo ""
    echo "#######################################################"
    echo "#######################################################"
    while [ "$1" != "" ]
    do
      echo "  $1"
      shift
    done
    echo "#######################################################"
    echo "#######################################################"
    echo ""
    cd ..
    exit_script $(( $errCode + $ERR_OFFSET ))
  fi
}

# Tis function generates the build install String.
# parameter '  ' = Product name
function buildStr()
{
  local NAME="$1"
  local MSG=()

  if [ $DO_MAKE -eq 1 ] ; then
    MSG+=("Make")
  fi
  if [ $DO_INSTALL -eq 1 ] ; then
    MSG+=("Install")
  fi
  if [ ${#MSG[@]} -gt 0 ] ; then
    AND_STR=""
    PRN_MSG=""
    for token in ${MSG[@]} ; do
      _MSG=$(echo "$_MSG$token$AND_STR")
      AND_STR=" and "
    done
    echo "$_MSG $NAME..."
  fi
}

# This function does the make and make install
# parameter $1 = Product name
function make_install()
{
  local NAME="$1"
  if [ $DO_MAKE -eq 1 ] ; then
    if [ -e Makefile ] ; then
      make -j 2
      check $? "Error building $NAME!" " " \
              "In case the error is triggered by:" \
              "\"WARNING: aclocal-1.13 is missing on your system.\"" \
              " " "Or similar, try paramerer -T or install the packages" \
              "automake and autoconf!"
    else
      check 1 "Error Makefile not found. Configure the project first!"
    fi
  fi
  if [ $DO_INSTALL -eq 1 ] ; then
    make install
    check $? "Error installing $NAME!"
  fi
  if [ $DO_DISTCLEAN -eq 1 ] ; then
    make uninstall
    check $? "Error uninstalling $NAME!"
    make distclean
    check $? "Error cleaning $NAME!"
  fi
  if [ $DO_UPDATE -eq 1 ] ; then
    $CRS_CMD fetch
    $CRS_CMD pull
  fi
  cd ..
}

checkParam $@
echo $SCRIPTNAME
disclaimer $AUTOMATED

# Check if a custom prefix location is to be used.
if [ "$PREFIX_PARAM" != "" ] ; then
  case $PREFIX_PARAM in 
    "use")
      if [ -e $PREFIX_PARAM_FILE ] ; then
        echo "Use $PREFIX_PARAM_FILE to specify binary prefix location!"
        source $PREFIX_PARAM_FILE
        echo "  * Modified: LOC_PREFIX=$LOC_PREFIX"
        echo "  * Modified: REL_LOC_PREFIX=$REL_LOC_PREFIX"
      else
        # Remove the param. This affects the vscode json generation
        PREFIX_PARAM=
      fi
      ;;
    "create")
        echo "Create parameter file $PREFIX_PARAM_FILE"
        echo "# Do NOT modify this file." > $PREFIX_PARAM_FILE
        echo "LOC_PREFIX=$LOC_PREFIX" >> $PREFIX_PARAM_FILE
        echo "REL_LOC_PREFIX=$REL_LOC_PREFIX" >> $PREFIX_PARAM_FILE
      
      ;;
    "delete")
      if [ -e $PREFIX_PARAM_FILE ] ; then
        echo "Remove parameter file $PREFIX_PARAM_FILE"
        rm -f $PREFIX_PARAM_FILE
      else
        echo "No need to remove $PREFIX_PARAM_FILE, it does not exist!"
      fi
      ;;
    *)
          
          ;;
  esac
fi

if [ $RUN_TEST -eq 1 ] ; then
  doTest
  exit $?
fi

if [ $DO_TOUCH_AUTOMAKE -eq 1 ] ; then
  touch_automake
fi

if [ $DO_VSCODE -eq 1 ] ; then
  if [ "$LOC_PREFIX" == "$REL_LOC_PREFIX" ]; then
    echo "The install directory for the binaries is modified!"
    echo "Please adjust the following settings in the .json files"
    echo "generated for the vscode project files:"
    echo "  * program"
    echo "  * SRxIncludePath"
    echo "  * QSRxIncludePath"
  fi
  createVsCode
fi


if [ $DO_SCA -eq 1 ] ; then
  # Make and install srx-crypto-api
  ERR_OFFSET=$ERR_OFFSET_SCA
  DIR=srx-crypto-api
  NAME=SRxCryptoAPI
  buildStr $NAME
  cd $DIR
  if [ $DO_CONFIGURE -eq 1 ] ; then
    # Check if a configure script exist, otherwise try to generate one!
    checkConfig
    ./configure --prefix=$LOC_PREFIX CFLAGS="-O0 -g" ${PARAM_SCA[@]}
    check $? "Error Configuring $NAME!"
  fi
  make_install $NAME
fi

if [ $DO_BIO -eq 1 ] ; then
  # Make and install bgpsec-io
  ERR_OFFSET=$ERR_OFFSET_BIO
  DIR=bgpsec-io
  NAME=BGPSEC-IO
  buildStr $NAME
  cd $DIR
  if [ $DO_CONFIGURE -eq 1 ] ; then
    # Check if a configure script exist, otherwise try to generate one!
    checkConfig
    ./configure --prefix=$LOC_PREFIX sca_dir=$LOC_PREFIX CFLAGS="-O0 -g" ${PARAM_BIO[@]}
    check $? "Error Configuring $NAME!"
  fi
  make_install $NAME
fi

if [ $DO_SRxSnP -eq 1 ] ; then
  # Make and install srx-server
  ERR_OFFSET=$ERR_OFFSET_SRxSnP
  DIR=srx-server
  NAME=SRx-Server
  buildStr $NAME
  cd $DIR
  if [ $DO_CONFIGURE -eq 1 ] ; then
    # Check if a configure script exist, otherwise try to generate one!
    checkConfig src
    ./configure --prefix=$LOC_PREFIX sca_dir=$LOC_PREFIX CFLAGS="-O0 -g" ${PARAM_SRxSnP[@]}
    check $? "Error Configuring $NAME!"
  fi
  make_install $NAME
fi

if [ $DO_QSRx -eq 1 ] ; then
  # Make and install quagga-srx
  ERR_OFFSET=$ERR_OFFSET_QSRx
  DIR=quagga-srx
  NAME=QuaggaSRx
  buildStr $NAME
  cd $DIR
  if [ $DO_CONFIGURE -eq 1 ] ; then
    # Check if a configure script exist, otherwise try to generate one!
    checkConfig
    ./configure --prefix=$LOC_PREFIX --disable-doc --enable-user=root --enable-group=root --enable-srx --enable-srxcryptoapi sca_dir=$LOC_PREFIX srx_dir=$LOC_PREFIX CFLAGS="-O0 -g" ${PARAM_QSRx[@]}
    check $? "Error Configuring $NAME!"
  fi
  make_install $NAME
fi
if [ $DO_EXAMPLES -eq 1 ] ; then
  ERR_OFFSET=$ERR_OFFSET_EXAMPLES
  DIR=examples
  NAME=EXAMPLES
  cd $DIR
  if [ $DO_CONFIGURE -eq 1 ] ; then
    ./configure.sh --no-interactive Y AUTO ${PARAM_EXAMPLES[@]}
    check $? "Error Configuring $NAME!"
  fi
  if [ $DO_INSTALL -eq 1 ] ; then
    ./install.sh $LOC_PREFIX
    check $? "Error installing $NAME!"
  fi
  if [ $DO_DISTCLEAN -eq 1 ] ; then
    ./configure.sh -R --no-interactive Y
    check $? "Error cleaning up configuration in $NAME!"
    ./uninstall.sh install.sh.log --no-interactive Y
    check $? "Error uninstalling $NAME!"
  fi
  if [ $DO_UPDATE -eq 1 ] ; then
    do_keep=( $DO_MAKE $DO_INSTALL $DO_DISTCLEAN )
    DO_MAKE=0
    DO_INSTALL=0
    DO_DISTCLEAN=0
    make_install $NAME
    DO_MAKE=${do_keep[0]}
    DO_INSTALL=${do_keep[1]}
    DO_DISTCLEAN=${do_keep[2]}
    do_keep=
  fi
fi
ERR_OFFSET=0
