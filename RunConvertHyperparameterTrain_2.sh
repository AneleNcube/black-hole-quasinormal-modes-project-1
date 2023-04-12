BLUE='\033[0;34m'
NC='\033[0m'

#########################################################
RunGenerate=true

####################################################################################
##### Pull the required Docker files#####
echo -e "${BLUE}Pulling Docker file for generating events${NC}"
sudo docker pull skaskid470/madgraph
echo -e "${BLUE}Pulling Docker file for running python scripts${NC}"
sudo docker pull skaskid470/pythonscripts
#### Finished pulling docker files
####################################################################################

###################################################################################
###Name Docker containers
DockerNameMADGraph=MADGraphDocker_Gerhard
DockerNamePython=PythonDocker_Gerhard
###################################################################################
SECONDS=0

###################################################################################
########Create temporary folders to hold the necessary files
cd 
cd Documents
mkdir DockerOutput_Gerhard 
cd $_
OUTPUT=$(pwd)

echo $OUTPUT

mkdir MADGraphScripts 
cd $_

git clone https://github.com/GerhardHarmsen/MADGraph
git clone https://github.com/GerhardHarmsen/Physics-Machine-Learning-project.git

cd MADGraph
cd Docker_Environment
tar -xzf MSSM_UFO.tgz

#####Temp folders hold all necessary files
###################################################################################

###################################################################################
#### Start docker files and copy across necessary files

#### MADGraph Docker setup
sudo docker run -dit --name $DockerNameMADGraph -v $OUTPUT/models:/var/UFO_models -v $OUTPUT/outputs:/var/MG_outputs skaskid470/madgraph bash

sudo docker cp $OUTPUT/MADGraphScripts/MADGraph/Docker_Environment/MSSM_UFO $DockerNameMADGraph:/home/hep/mg5amcnlo/models

#### Python docker setup
sudo docker run -dit --name $DockerNamePython -v $OUTPUT/outputs:/usr/src/app skaskid470/pythonscripts bash

sudo docker cp $OUTPUT/MADGraphScripts/Physics-Machine-Learning-project $DockerNamePython:/usr/src/app

cd ..
cd ..
###### Docker setup complete 
####################################################################################

####################################################################################
####### Start creating bash files to generate events
######################## Setup directories for easy saving of results ############
############## Variables for the scripts #########################################
BACKGROUNDRUNS=20
SIGNALRUNS=5
EVENTSPERRUN=10000

#NEUTRALINOMASS=(175 87 125 100 150 70 100 68 120 150 75 300 500 440 260 270 220 190 140 130 140 95 80 60 60 65 55 200 190 180 96 195 96 195)
#SMUONMASS=(350 350 375 260 300 350 300 275 475 300 450 310 510 450 275 360 320 290 240 240 420 500 400 510 200 210 250 450 500 400 200 200 400 400)

NEUTRALINOMASS=(270 220 190 140 130 140 95 80 60 60 65 55 200 190 180 195 96 195 96 175 87 125 100 70 100 68 120 150 75 300 500 440 260)
SMUONMASS=(360 320 290 240 240 420 500 400 510 200 210 250 450 500 400 400 400 200 200 350 350 375 260 350 300 275 475 300 450 310 510 450 275)

len=${#SMUONMASS[@]}

############## Variables for the scripts #########################################
############## Background events #################################################
if [ "$RunGenerate" = true ]
then
FILE="PPtoTopTopBar"

/bin/cat <<EOM>$FILE
####################################################################################
#####File Generates the following
##### Proton Proton to top top-bar with two jets
##### With $((BACKGROUNDRUNS * EVENTSPERRUN)) events
##### xqcut value of 30
####################################################################################
define l+ = e+ mu+ ta+ 
define l- = e- mu- ta-
generate p p > t t~ @0
add process p p > t t~ j @1
add process p p > t t~ j j @2
output ./Background/Events_${FILE}
launch ./Background/Events_${FILE} -i
multi_run ${BACKGROUNDRUNS}
1
2
4
0
set ebeam = 6500
set nevents = ${EVENTSPERRUN}
set ickkw = 1
decay t > w+ b, w+ > l+ vl
decay t~ > w- b~, w- > l- vl~
set xqcut = 30
set etaj = 5
0
EOM

sudo docker cp $OUTPUT/MADGraphScripts/$FILE $DockerNameMADGraph:/var/MG_outputs

/bin/cat <<EOM>>'BashFile.sh'
/home/hep/mg5amcnlo/bin/mg5_aMC $FILE &
EOM

FILE="PP_W_LeptonNeutrino"
/bin/cat <<EOM>$FILE
####################################################################################
##### File Generates the following
##### Proton Proton to lepton neutrino pairs with two jets (These smuons decay to muons) 
##### With $((BACKGROUNDRUNS * EVENTSPERRUN)) events
##### xqcut value of 25
####################################################################################
define l+ = e+ mu+ ta+ 
define l- = e- mu- ta-
define ll = l+ l-
define vv = vl vl~
generate p p > ll vv @0
add process p p > ll vv j @1
add process p p > ll vv j j  @2
output ./Background/Events_${FILE}
launch ./Background/Events_${FILE} -i
multi_run ${BACKGROUNDRUNS}
1
2
0
set ebeam = 6500
set nevents = ${EVENTSPERRUN}
set ickkw = 1
set xqcut = 25
set etaj = 5
0
EOM

sudo docker cp $OUTPUT/MADGraphScripts/$FILE $DockerNameMADGraph:/var/MG_outputs

/bin/cat <<EOM>>'BashFile.sh'
/home/hep/mg5amcnlo/bin/mg5_aMC $FILE &
EOM


FILE="PP_WW_lvl"
/bin/cat <<EOM>$FILE
####################################################################################
##### File Generates the following
##### Proton Proton to lepton neutrino pairs with two jets (These smuons decay to muons) 
##### With $((BACKGROUNDRUNS * EVENTSPERRUN)) events
##### xqcut value of 25
####################################################################################
define l+ = e+ mu+ ta+ 
define l- = e- mu- ta-
generate  p p > w+ w-, ( w+ > l+ vl ), ( w- > l- vl~ ) @0
add process p p > w+ w- j, ( w+ > l+ vl ), ( w- > l- vl~ ) @1
add process p p > w+ w- j j, ( w+ > l+ vl ), ( w- > l- vl~ ) @2
output ./Background/Events_${FILE}
launch ./Background/Events_${FILE} -i
multi_run ${BACKGROUNDRUNS}
1
2
0
set ebeam = 6500
set nevents = ${EVENTSPERRUN}
set ickkw = 1
set xqcut = 25
set etaj = 5
0
EOM

sudo docker cp $OUTPUT/MADGraphScripts/$FILE $DockerNameMADGraph:/var/MG_outputs

/bin/cat <<EOM>>'BashFile.sh'
/home/hep/mg5amcnlo/bin/mg5_aMC $FILE &
EOM

#### Background events setup
#### Setup signal events

len=${#SMUONMASS[@]}

for ((i=0; i<$len; i++))
do

FILE="PPtoSmuonSmuon_Smuon_Mass_${SMUONMASS[$i]}_Neutralino_${NEUTRALINOMASS[$i]}"
/bin/cat <<EOM >>$FILE
####################################################################################
##### File Generates the following
##### Proton Proton to smuon pair with two jets (These smuons decay to muons) 
##### With $((SIGNALRUNS * EVENTSPERRUN)) events
##### xqcut value of 55
####################################################################################
import model MSSM_UFO/
generate p p > mur- mur+ @0
add process p p > mur- mur+ j @1
add process p p > mur- mur+ j j @2
output ./Signal/Events_${FILE}
launch ./Signal/Events_${FILE} -i
multi_run ${SIGNALRUNS}
1
2
4
0
decay mur- > mu- n1
decay mur+ > mu+ n1
set ebeam = 6500
set nevents = ${EVENTSPERRUN}
set ickkw = 1
set xqcut = 55
set etaj = 5
set mass 2000013 ${SMUONMASS[$i]}
set mass 1000022 ${NEUTRALINOMASS[$i]}
0
EOM


sudo docker cp $OUTPUT/MADGraphScripts/$FILE $DockerNameMADGraph:/var/MG_outputs

/bin/cat <<EOM>>'BashFile.sh'
/home/hep/mg5amcnlo/bin/mg5_aMC $FILE &
EOM
done

/bin/cat <<EOM>>'BashFile.sh'
wait
EOM

sudo docker cp $OUTPUT/MADGraphScripts/BashFile.sh $DockerNameMADGraph:/var/MG_outputs
sudo docker exec -it $DockerNameMADGraph bash /var/MG_outputs/BashFile.sh 
fi

ELAPSED=" $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo -e "${BLUE}Job Completed in ${ELAPSED} ${NC}"

sudo docker kill $DockerNameMADGraph
sudo docker rm $DockerNameMADGraph

####Events generated with root outputs
########################################################################################
########################################################################################
###### Convert files to CSV

SECONDS=0

FILE="ConvertScripts.sh"
/bin/cat <<EOM >$FILE
####################################################################################
##### File will convert the DElphes files to CSV files
####################################################################################
mkdir CSV
cd CSV
EOM

for ((i=0; i<$len; i++))
do

/bin/cat <<EOM >>$FILE
mkdir Events_PPtoSmuonSmuon_Smuon_Mass_${SMUONMASS[$i]}_Neutralino_${NEUTRALINOMASS[$i]}
cd ..
cd Physics-Machine-Learning-project
python -c "import DelphesToCSV; DelphesToCSV.DELPHESTOCSV2(1, r'/usr/src/app/Signal/Events_PPtoSmuonSmuon_Smuon_Mass_${SMUONMASS[$i]}_Neutralino_${NEUTRALINOMASS[$i]}',r'/usr/src/app/CSV/Events_PPtoSmuonSmuon_Smuon_Mass_${SMUONMASS[$i]}_Neutralino_${NEUTRALINOMASS[$i]}')" &
cd ..
cd CSV
EOM
done

/bin/cat <<EOM >>$FILE
mkdir Background
cd ..
cd Physics-Machine-Learning-project
python -c "import DelphesToCSV; DelphesToCSV.DELPHESTOCSV2(0, r'/usr/src/app/Background',r'/usr/src/app/CSV/Background')" &
cd ..
wait 
EOM

sudo docker cp $OUTPUT/MADGraphScripts/$FILE $DockerNamePython:/usr/src/app

#### Hyperparameter training

FILE="HyperparameterTrain.sh"
/bin/cat <<EOM >$FILE
cd Physics-Machine-Learning-project

EOM


for ((i=0; i<$len; i++))
do
/bin/cat <<EOM >>$FILE
python -c  "import HyperParameterTuning; HyperParameterTuning.HyperParameters(${SMUONMASS[$i]},${NEUTRALINOMASS[$i]},r'/usr/src/app/CSV/',r'/usr/src/app/CSV/Background')" 
EOM

done

/bin/cat <<EOM >>$FILE
#python -c  "import HyperParameterTuning; HyperParameterTuning.CombineJSON(r'/usr/src/app/CSV/',r'/usr/src/app/CSV/')" 
cd ..
EOM

sudo docker cp $OUTPUT/MADGraphScripts/$FILE $DockerNamePython:/usr/src/app

#### Run the Python scripts in the docker container
#### I have written it this way so that the sudo password is only requested twice.

FILE='RunPythonScripts'
/bin/cat <<EOM >$FILE
bash ConvertScripts.sh
bash HyperparameterTrain.sh
wait
EOM

#### Run the Python scripts in the docker container

sudo docker cp $OUTPUT/MADGraphScripts/$FILE $DockerNamePython:/usr/src/app

echo Copied python scripts

sudo docker exec -it $DockerNamePython bash /usr/src/app/$FILE

ELAPSED=" $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo -e "${BLUE}Job Completed in ${ELAPSED} ${NC}"
##########################################################################

sudo docker kill $DockerNamePython
sudo docker rm $DockerNamePython
cd .. 
sudo rm -r MADGraphScripts
