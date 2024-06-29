#!/bin/bash

# Função para solicitar origem e destino do backup
solicitar_origem_destino() {
    echo "Por favor, forneça o caminho da pasta de ORIGEM (começando da raiz):"
    read -r origem_backup
    echo "Por favor, forneça o caminho da pasta de DESTINO (começando da raiz):"
    read -r destino_backup
    echo "Você escolheu a origem: $origem_backup"
    echo "E o destino: $destino_backup"
    echo "Está correto? (S/n)"
    read -r confirmacao
}

# Função para definir o local onde o script de backup será salvo
definir_local_script() {
    echo "Onde você gostaria de salvar o script de backup?"
    echo "Digite o caminho completo desde a raiz ou deixe em branco para salvar no diretório atual."
    read -r destino
    if [[ -n $destino ]]; then
        target="$destino/backup_$nome.sh"
    else
        target="$(pwd)/$nome.sh"
    fi
}

# Solicitar a frequência de execução do backup
definir_frequencia() {
    echo "Escolha a frequência para a execução do backup:"
    echo "1. Diariamente"
    echo "2. Semanalmente"
    echo "3. Mensalmente"
    echo "4. Anualmente"
    read -r frequencia

    case $frequencia in
        1)
            cron_schedule="0 0 * * *"
            ;;
        2)
            cron_schedule="0 0 * * 0"
            ;;
        3)
            cron_schedule="0 0 1 * *"
            ;;
        4)
            cron_schedule="0 0 1 1 *"
            ;;
        *)
            echo "Opção inválida. Por favor, execute o script novamente e escolha uma opção válida."
            exit 1
            ;;
    esac
}

clear

solicitar_origem_destino
while [[ $confirmacao != "S" && $confirmacao != "s" ]]; do
    solicitar_origem_destino
done

echo "Informe um nome para o backup (isso permite múltiplos backups com origens e destinos diferentes):"
read -r nome

diretorio_atual=$(pwd)
definir_local_script
while [[ $destino == $destino_backup || $destino == $origem_backup ]]; do
    clear
    echo "O script de backup não pode estar na pasta de origem ou destino!"
    definir_local_script
done

definir_frequencia

# Adicionar o novo cron job
(crontab -l 2>/dev/null; echo "$cron_schedule bash $target") | crontab -

clear
echo "Você deseja que o backup realize uma sincronização completa no destino? (S/n)"
echo "(Isso removerá arquivos do destino que não estejam na origem)"
read -r opcao

# Criar o script de backup com os caminhos definidos
{
    echo "#!/bin/bash"
    echo
    echo "cp $destino_backup/logBackup.txt $origem_backup/log.txt 2>/dev/null || true"
    if [[ $opcao == 's' || $opcao == 'S' ]]; then
        echo "rsync -av --log-file=$origem_backup/log.txt --exclude=logBackup.txt --delete --progress $origem_backup/ $destino_backup/"
    else
        echo "rsync -av --log-file=$origem_backup/log.txt --exclude=logBackup.txt --progress $origem_backup/ $destino_backup/"
    fi
    echo "cat $origem_backup/log.txt >> $destino_backup/logBackup.txt"
    echo "echo '-------------------------------------------' >> $destino_backup/logBackup.txt"
    echo "rm -f $origem_backup/log.txt"
    echo "rm -f $destino_backup/log.txt"
} > "$target"

# Tornar o script de backup gerado executável
chmod +x "$target"

echo "O script de backup foi criado em: $target"
echo "Backup agendado conforme a frequência especificada."
