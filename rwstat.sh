#!/bin/bash
#for that intereates throught all arguments less the last one




ultimo=${@: -1}                                                             # guarda o ultimo argumento --> tempo
NrArgs=$#                                                                   # guarda o numero total de argumentos 
declare -a argumentos=("$@")                                                # guarda os argumentos numa array

declare -A argOpt=() 

declare -A AllArray                                                         #declarar um array associativo para guardar a informação de todos os processos

valR=0                                                                      #variavel para distinguir quando alterar a ordem de AllArray
valW=0                                                                      #variavel para distinguir quando alterar a ordem de AllArray apartir dos WRITEB

countM=0
countm=0
countP=0

countArg=0                                                                  #variavel que conta os argumentos sem significado


declare -A meses
meses=(["Jan"]=01 ["Feb"]=02 ["Mar"]=03 ["Apr"]=04 ["May"]=05 ["Jun"]=06 ["Jul"]=07 ["Aug"]=08 ["Sep"]=09 ["Oct"]=10 ["Nov"]=11 ["Dec"]=12)
 


function ValArgs(){
    if [ $NrArgs -eq 0 ]; then
        echo "Não existem argumentos"
        exit 1
    fi
}

function valTempo(){
    
    if [[ $ultimo =~ ^[0-9]+$ ]] && [[ $ultimo -gt 0 ]]; then               #verifica se o ultimo argumento é um numero e se é maior que 0
        return 1
    else
        echo "O tempo tem que ser um inteiro e positivo"
        exit
    fi
}

function printTable(){
    printf "%-20s %-10s %10s %15s %15s %15s %15s %15s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE";
}

function getInitialValues(){
    pid=$(ps -ef  | grep 'p' | awk '{print $2}')

    for processos in $pid ;do
        if [ -d  $processos ];then
            cd ./$processos
            if [ -r ./io ];then
                

                rchar=$(cat /proc/$processos/io | grep rchar |   grep -o -E '[0-9]+'  )
                allRchar[$processos]=$rchar                                 #allRchar guarda os valores iniciais de rchar           
        
                wchar=$(cat /proc/$processos/io | grep wchar |  grep -o -E '[0-9]+'  )
                allWchar[$processos]=$wchar                                 #allWchar guarda o valores iniciais de wchar

            fi
            cd ../
        fi
    done
};

function getSecondValues(){
    for processos in $pid ;do
        if [ -d  $processos ];then
            cd ./$processos
            if [ -r ./io ];then
                name=$(grep -E "Name" ./status | awk '{print $2}')

                owner=$(ps -p $processos -o user=)

                rchar2=$(cat /proc/$processos/io | grep rchar |   grep -o -E '[0-9]+'  )                              

                difR=$((rchar2-allRchar[$processos]))
                rateR=$(echo "scale=2; $difR/$ultimo" | bc -l) # calculo do rateR

                wchar2=$(cat /proc/$processos/io | grep wchar |  grep -o -E '[0-9]+'  )

                difW=$((wchar2-allWchar[$processos]))
                rateW=$(echo "scale=2; $difW/$ultimo" | bc -l) # calculo do rateW

                date=$(ps -p $processos -o lstart=)
                date=$(echo $date | awk '{print $2,$3,$4}')                 #Retira o mês, o dia e Horas:Min:Seg ---> de date
                

                month=$(echo $date | awk '{print $1}')
                month=${meses[$month]}                                      #Retira o mês em numero
                
                day=$(echo $date | awk '{print $2}')
                if [[ $day -lt 10 ]]; then
                    day="0$day"
                fi

                hour=$(echo $date | awk '{print $3}' | awk -F: '{print $1}')
                minutes=$(echo $date | awk '{print $3}' | awk -F: '{print $2}')

                #add month day hour and minutes but without summing them
                dateAtual=$(echo $month $day $hour $minutes | awk '{printf "%s%s%s%s",$1,$2,$3,$4}')
                #turn dateAtual into int
                dateAtual=$(echo $dateAtual | awk '{print $1}')             #Data atual em int MesDiaHoraMin
                
                

                #inicialize testeC  
                testeC=0
                if [ -z "${argsU}" ]; then    #verifica se existe algum filtro para o USER
                    testeU=$owner           #se não existir, ou seja, se o array estiver vazio o valor testeU é igual ao USER do processo
                else
                    testeU=$argsU           #se existir, o valor testeU é a variavel $argsU
                fi

                if [ -z "${argsC}" ]; then    #verifica se existe algum filtro para o COMM
                    testeC=$name            #se nao existir, ou seja, se o array estiver vazio o valor de testeC é o nome do processo
                else
                    testeC=$argsC           #se existir, o valor de testeC é a variavel $argsC
                fi

                if [ -z ${argsm} ]; then    #verifica se existe algum filtro para valores minimos de PID
                    testem=$processos       #se não existir, ou seja, se o array estiver vazio o valor de testem é o PID do processo
                else
                    testem=$argsm           #se existir, o valor de testem é a variavel $argsm
                fi

                if [ -z ${argsM} ]; then    #verifica se existe algum filtro para valores maximos de PID
                    testeM=$processos       #se não existir, ou seja, se o array estiver vazio o valor de testeM é o PID do processo
                else
                    testeM=$argsM           #se existir, o valor de testeM é a variavel $argsM  
                fi

                if [ -z ${argsS} ]; then    #verifica se existe algum filtro para data minima
                    testeS=$dateAtual       #se não existir, ou seja, se o array estiver vazio o valor de testeS é a data atual do processo
                else
                    testeS=$argsS           #se existir, o valor de testeS é a variavel $argsS
                fi

                if [ -z ${argsE} ]; then    #verifica se existe algum filtro para data maxima
                    testeE=$dateAtual       #se não existir, ou seja, se o array estiver vazio o valor de testeS é a data atual do processo
                else
                    testeE=$argsE           #se existir, o valor de testeE é a variavel $argsE

                    

                fi
                
                

                if [[ $owner =~ $testeU ]] && [[ $name =~ $testeC ]] && [[ $testem -le $processos ]] && [[ $testeM -ge $processos ]] && [[ $testeS -le $dateAtual ]] && [[ $testeE -ge $dateAtual ]]; then

                    AllArray[$processos]=$(printf "%-20s %-10s %10s %15s %15s %15s %15s %20s \n" "$name" "$owner" "$processos" "$difR" "$difW" "$rateR" "$rateW" "$date")

                fi
               
               fi
            cd ../
        fi
    done
    
    if [ -z ${argsP} ]; then                                                #verifica se existe algum filtro para nr de processos a mostrar
        testeP=${#AllArray[@]}                                              #se não existir, o nr de processos a mostrar é o numero de processos total     
    else

        testeP=$argsP                                                       #se existir, o nr de processos a mostrar é o valor do argumento
        if [ $testeP -gt ${#AllArray[@]} ]; then                            #verifica se o valor do argumento é maior que o nr de processos, se for sai do programa
            echo "O numero de processos que quer mostrar é maior que o numero de processos existentes"
            exit
        fi
    fi
   

    if [ $valR -eq 1 ]; then                                                
        ordemRev="-n"                                                      #verifica se o $valR é igual a 1, vamos alterar a ordenação da tabela (reverse)  
       
    else
        ordemRev="-rn"
    fi

    if [ $valW -eq 1 ]; then
        ordemW="-k7"                                                        #Se existir o filtro -w, vamos ordenar a tabela pelo nr de bytes escritos                                                 
    else
        ordemW="-k6"                                                        #Se não existir o filtro -w, vamos ordenar a tabela pelo nome do processo
    fi

    #print apenas os primeiros $testeP processos de ordem reversa ou não, ou consoante os WRITEB 
    
    printf '%s \n' "${AllArray[@]}" | sort $ordemRev $ordemW | head -n $testeP     
                     
}

#verificar argumentos sem significado
i=0
while [[ $i -lt $# ]]
do


    if [[ ${argumentos[$i]} != -* ]] && [[ $i -lt $#-1 ]] 
    then

        echo "O Argumento de índice: $i e de valor: ${argumentos[$i]} não tem utilidade"
        countArg=$((countArg+1))
    fi
    if [[ ${argumentos[$i]} == "-w" ]] || [[ ${argumentos[$i]} == "-r" ]]
    then
        i=$((i+1))
    elif [[ ${argumentos[$i]} == -* ]]                 #se encontrar-mos um argumento com "-" avançamos dois argumentos que são o do "-" e o seguinte
    then
        i=$((i+2))
    else 
        i=$((i+1))
    fi
  
done

if [[ $countArg -ne 0 ]]
then
    exit
fi

while getopts "c:s:e:u:m:M:p:rw" argumentos; do

    if [[ "$OPTARG" ]]; then
        argOpt[$argumentos]=${OPTARG}
    else
        argOpt[$argumentos]=0
    fi

    case $argumentos in 
        c)

            argsC=${argOpt['c']}
          
            if [[ $argsC == -* ]]; then                                         #o valor seguinte a -c tem que ser um inteiro, não pode ser outro filtro
                echo "Argumento -c não pode começar com -"
                exit
            fi

            if [[ $argsC =~ ^[0-9]+$ ]]; then                                   #o valor depois de -c tem que ser uma string
                echo "Formato incorreto!!        -c [String nome_processo], último argumento [int TEMPO]"
                exit
            fi
            
            printf "nome do PID: %s\n" $argsC

        ;;

        s)
            argsS=${argOpt['s']}
           
            nrArgsS=$(echo $argsS | awk '{print NF}')                       #nr de argumentos do -s

            mes=$(echo $argsS | awk '{print $1}')

            if [ $nrArgsS -ne 3 ]; then                                     #a data tem de ter 3 argumentos
                echo "Formato incorreto!!         -s [String mes] [int dia] [int hora: int minutos], último argumento [int TEMPO]"
                exit
            fi

            if [[ $mes =~ ^[0-9]+$ ]] || [[ ! ${meses[$mes]} ]]; then       #verifica se o mes está bem colocado
                echo "Nome do mês: Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec"
                exit
            fi

            mes=${meses[$mes]}
            
            dia=$(echo $argsS | awk '{print $2}')
            
            if [[ $dia -lt 10 ]]; then
                dia="0$dia"
                
            fi

            if [[ ! $dia =~ ^[0-9]+$ ]]; then
                echo "Formato incorreto!!       -s [String mes] [int dia] [int hora:int minutos], último argumento [int TEMPO]"
                exit
            fi
         
            if [ $dia -lt 1 ] || [ $dia -gt 31 ]; then
                echo "O dia deve ser um nr entre 1 e 31"
                exit
            fi

            hora_Min=$(echo $argsS | awk '{print $3}')
            hora=$(echo $hora_Min | awk -F: '{print $1}')
            min=$(echo $hora_Min | awk -F: '{print $2}')

            if [[ ${#hora_Min} -ne 5 ]] || [[ ${hora_Min:2:1} != ":" ]]; then
                echo "Formato incorreto!!       -s [String mes] [int dia] [int hora: int minutos], último argumento [int TEMPO]"
                exit
            fi 
            
            argsS=""                                                        #A variavel argsS é esvaziada    
            argsS=$(echo $mes $dia $hora $min | awk '{printf "%s%s%s%s",$1,$2,$3,$4}')
  
            argsS=$(echo $argsS | awk '{print int($1)}')                    #A variavel argsS é convertida para inteiro --> mesdiahoraMin
            printf "Data minima (tudo junto): %d\n" $argsS
        ;;

        e)
            argsE=${argOpt['e']}
            nrArgsE=$(echo $argsE | awk '{print NF}')                       #nr de argumentos do -e
        
            if [ $nrArgsE -ne 3 ]; then                                     #a data tem que ter 3 argumentos
                echo "Formato incorreto!!        -e [String mes] [int dia] [int hora: int minutos], último argumento [int TEMPO]"
                exit
            fi
            mesE=$(echo $argsE | awk '{print $1}')

            if [[ $mesE =~ ^[0-9]+$ ]] || [[ ! ${meses[$mesE]} ]]; then
                echo "Nome do mês: Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec"
                exit
            fi

            mesE=${meses[$mesE]}
            
            diaE=$(echo $argsE | awk '{print $2}')
            
            if [[ $diaE -lt 10 ]]; then
                diaE="0$diaE"
                
            fi
    
            if [ $diaE -lt 1 ] || [ $diaE -gt 31 ]; then
                echo "O dia deve ser um nr entre 1 e 31"
                exit
            fi

            hora_MinE=$(echo $argsE | awk '{print $3}')
            horaE=$(echo $hora_MinE | awk -F: '{print $1}')
            minE=$(echo $hora_MinE | awk -F: '{print $2}')

            if [[ ${#hora_MinE} -ne 5 ]] || [[ ${hora_MinE:2:1} != ":" ]]; then
                echo "Formato incorreto!!       -e [String mes] [int dia] [int hora: int minutos], último argumento [int TEMPO]"
                exit
            fi 
            
            argsE=""                                                        #A variavel argsS é esvaziada    
            #store in argsS mes dia hora min
            argsE=$(echo $mesE $diaE $horaE $minE | awk '{printf "%s%s%s%s",$1,$2,$3,$4}')
            #turn argsS to int
            argsE=$(echo $argsE | awk '{print int($1)}')                    #A variavel argsS é convertida para inteiro
            printf "Data maxima (tudo junto): %d\n" $argsE
        ;;

        u)
            argsU=${argOpt['u']}
            #check if argsU starts with "-"
            if [[ $argsU == -* ]]; then
                 echo "Argumento -u não pode começar com -"
                exit
            fi

            if [[ $argsU =~ ^[0-9]+$ ]]; then
                echo "Formato incorreto!!       -u [String nome_utilizador], último argumento [int TEMPO]"
                exit
            fi
            
            printf "USER: %s\n" $argsU
        ;;

        m)
            argsm=${argOpt['m']}
            
            allLastButm=$(echo $@ | awk '{for(i=1;i<NF;i++) printf "%s ",$i}') #remove o ultimo argumento
            
            arrm=$(echo $allLastButm | awk -F"-m" '{print $2}')
            
            for i in $arrm; do
                if [[ $i =~ ^- ]]; then
                   
                    break
                fi
                countm=$((countm+1))
            done
           
            if [ $countm -ne 1 ]; then
                echo "Formato incorreto!!      -m [int PID_minimo], último argumento [int TEMPO]"
                exit
            fi

            #check if argsm is a number
            if [[ $argsm =~ ^[0-9]+$ ]]; then
                printf "PID minimo: %d\n" $argsm
                
            else
                echo "Formato correto!!       -m [int PID_minimo], último argumento [int TEMPO]"
                exit
            fi
        ;;

        M)
            argsM=${argOpt['M']}
            
            allLastButM=$(echo $@ | awk '{for(j=1;j<NF;j++) printf "%s ",$j}') #remove o ultimo argumento
            arrM=$(echo $allLastButM | awk -F"-M" '{print $2}')
            
            for i in $arrM; do
                if [[ $i =~ ^- ]]; then
                    break
                fi
                countM=$(($countM+1))
            done

            if [ $countM -ne 1 ]; then
                echo "Formato incorreto!!    -M [int PID_maximo], último argumento [int TEMPO]"
                exit
            fi
            
            
           
            if [[ $argsM =~ ^[0-9]+$ ]]; then      #O valor a seguir a -M tem que ser um numero inteiro e o array argsM só pode ter 1 elemento
                printf "PID maximo: %d\n" $argsM
                
            else
                echo "Formato incorreto!!    -M [int PID_maximo], último argumento [int TEMPO]"
                exit
            fi
        ;;

        p)
            argsP=${argOpt['p']}

          
            allLastButP=$(echo $@ | awk '{for(k=1;k<NF;k++) printf "%s ",$k}') #remove o ultimo argumento
            arrP=$(echo $allLastButP | awk -F"-p" '{print $2}')
            

            for i in $arrP; do
                if [[ $i =~ ^- ]]; then
                    break
                fi
                countP=$(($countP+1))
            done

            if [ $countP -ne 1 ]; then
                echo "Formato incorreto!!    -p [int Nr_PIDs], último argumento [int TEMPO]"
                exit
            fi
        

            if [[ $argsP =~ ^[0-9]+$ ]]; then                               #O valor a seguir a -p tem que ser um inteiro
                printf "nr PIDs: %d\n" $argsP
                
            else
                echo "Formato incorreto!!    -p [int Nr_PIDs], último argumento [int TEMPO]"
                exit
            fi
        ;;

        r)
            valR=1
            posR=$(echo $@ | awk '{for(i=1;i<=NF;i++) if($i=="-r") print $(i+1)}')          #argumento a seguir ao -r
            
            penultimoR=$(echo $@ | awk '{print $(NF-1)}')                                   #penultimo argumento    
           
            if [ ! $penultimoR == "-r" ]; then
                #O Valor a seguir a -r tem que ser ou o tempo ou outro filtro
                if [ $posR == "-c" ] || [ $posR == "-s" ] || [ $posR == "-e" ] || [ $posR == "-u" ] || [ $posR == "-m" ] || [ $posR == "-M" ] || [ $posR == "-p" ] || [ $posR == "-w" ]; then
                    echo 
                else
                    echo "Formato incorreto!!     -r, último argumento [int TEMPO]"
                    exit   
                fi  
            fi

        ;;
        
        w)
            valW=1

            posW=$(echo $@ | awk '{for(i=1;i<=NF;i++) if($i=="-w") print $(i+1)}')          #argumento a seguir ao -w
            
            penultimoW=$(echo $@ | awk '{print $(NF-1)}')                                   #penultimo argumento    

            if [ ! $penultimoW == "-w" ]; then
                #O Valor a seguir a -w tem que ser ou o tempo ou outro filtro
                if [ $posW == "-c" ] || [ $posW == "-s" ] || [ $posW == "-e" ] || [ $posW == "-u" ] || [ $posW == "-m" ] || [ $posW == "-M" ] || [ $posW == "-p" ] || [ $posW == "-r" ]; then
                    echo 
                else
                    echo "Formato incorreto!!      -w, último argumento [int TEMPO]"
                    exit   
                fi  
            fi

        ;;

        *)
            echo "COMANDO INVALIDO"
            exit 
        ;;
    esac
done


#main function
function main(){

    cd /proc/
    
    ValArgs
    valTempo
    
    printTable
    getInitialValues


    sleep $ultimo
    printf "\n\n"


    getSecondValues
}

main

