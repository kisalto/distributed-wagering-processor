gh auth login
gh auth refresh -s project
chmod +x criar-cards.sh
DRY_RUN=1 ./criar-cards.sh                                   # simula sem criar nada
PROJECT="Distributed Wagering Processor" ./criar-cards.sh    # cria de verdade