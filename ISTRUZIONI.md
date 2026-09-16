# AWS in casa — istruzioni del laboratorio

**Corso:** ACA · UF3 Automation e Pipeline con AWS
**Durata:** 4 ore
**Cosa costruisci:** una pipeline `Sorgente → Build → Deploy` che gira **sul tuo computer**, senza account AWS, senza carta di credito, senza Learner Lab.

Questo file è **autosufficiente**. Se ti perdi, se resti indietro, se eri assente o se stasera vuoi rifare tutto da casa, qui dentro c'è ogni comando con **cosa fa** e **perché lo stiamo facendo**.

---

## Come si legge questo file

Ogni passo è fatto sempre allo stesso modo:

> **IL COMANDO** — quello che scrivi nel terminale
> **COSA FA** — a parole, pezzo per pezzo, opzioni comprese
> **PERCHÉ** — a cosa serve nel discorso che stiamo facendo
> **COSA DEVI VEDERE** — come fai a sapere che è andata bene
> **SE NON FUNZIONA** — l'errore probabile e cosa fare

### Le tre regole

1. **Scrivi i comandi, non copiarli a raffica.** Servono le dita, non il copia-incolla.
2. **Se un comando fallisce, fermati.** Non andare avanti sperando: l'errore dice quasi sempre cosa manca.
3. **Se sei bloccato da più di 5 minuti sullo stesso errore, alza la mano.** Non si perde mezz'ora in silenzio.

Negli script dentro `scripts/` c'è la **soluzione di ogni fase**. Servono a sbloccarti, non a saltare la fase.

---

## Glossario minimo

Sette parole. Se queste sono chiare, il resto della giornata si segue.

| Parola | Cosa vuol dire davvero |
|---|---|
| **Emulatore** | Un programma che risponde come se fosse AWS, ma gira sul tuo computer |
| **Endpoint** | L'indirizzo a cui il comando manda la richiesta. Su AWS vero è `amazonaws.com`, oggi è `localhost:4566` |
| **Bucket** | Una cartella di S3. Ci metti dentro file, e può essere servita come sito web |
| **Stack** | Un gruppo di risorse create insieme da un file di CloudFormation, e di cui qualcuno tiene il conto |
| **Artefatto** | Il risultato della build: i file pronti da pubblicare. Usa e getta, si rifà sempre uguale |
| **Stage** | Una fase della pipeline. Le nostre sono tre: Sorgente, Build, Deploy |
| **Container** | Una scatola isolata in cui gira un programma, sempre uguale ovunque la apri |

---

## Mappa dei file — cosa c'è nel repo e quando lo tocchi

| File / cartella | Cos'è | Lo modifichi? |
|---|---|---|
| `sito/` | I sorgenti del sito: `index.html`, `style.css` | **Sì**, è l'unica cosa che modifichi a mano |
| `build.sh` | Copia `sito/` in `dist/` e ci timbra il numero di build | Lo leggi, non lo tocchi |
| `test.sh` | Sei controlli sull'artefatto. Se uno fallisce, esce con errore | Lo leggi, non lo tocchi |
| `buildspec.yml` | Le istruzioni per CodeBuild: cosa eseguire e cosa consegnare | Lo leggi |
| `infra/01-sito.yaml` | Il bucket del sito, scritto come codice (CloudFormation) | **Sì**, nella Fase 2 ne cambi una riga |
| `infra/pipeline.json` | I tre stage della pipeline | Lo leggi con attenzione |
| `infra/codebuild-progetto.json` | Il progetto CodeBuild della Fase 3 (sorgente da S3) | Lo leggi |
| `infra/codebuild-progetto-pipeline.json` | Il progetto CodeBuild della Fase 4 (sorgente dalla pipeline) | Lo leggi |
| `infra/ruolo-*.json` | Il ruolo di servizio e i suoi permessi | Lo leggi |
| `docker-compose.yml` | Come si accende LocalStack | Non lo tocchi |
| `.env` | Il tuo token personale di LocalStack | **Sì**, lo crei tu |
| `scripts/` | Preflight, soluzioni delle fasi, anteprima, pulizia | Li leggi e li lanci |
| `deliverables/risposte.md` | La traccia della consegna | **Sì**, è quello che consegni |
| `dist/` | L'artefatto prodotto dalla build | **Mai**: si rigenera e cancella le tue modifiche |

---

# FASE 0 — Accendere l'ambiente
**25 minuti · la fanno tutti**

Obiettivo: avere un AWS finto acceso sul tuo computer e sapere quali servizi ti dà.

---

## 0.1 — Apri il laboratorio

### Strada A — GitHub Codespaces (consigliata)

Non installi niente sul tuo portatile e siamo tutti sullo stesso ambiente.

1. Apri il repo del laboratorio su GitHub.
2. Bottone verde **Code** → scheda **Codespaces** → **Create codespace on main**.
3. Aspetta 2-3 minuti: sta costruendo una macchina Linux per te, con dentro Docker e l'AWS CLI già installati.
4. Quando compare il terminale in basso, sei dentro.

**Perché Codespaces:** su venti portatili diversi, mezza mattinata se ne va in «sul mio non parte». Qui l'ambiente è identico per tutti e lo butti via a fine giornata.

### Strada B — sul tuo computer

Solo se hai già **Docker Desktop** installato **e avviato**.

```bash
git clone <url-del-repo>
cd its-aws-in-casa
```

**`git clone`** scarica il repo sul tuo computer. **`cd`** ci entra dentro: da qui in poi tutti i comandi si lanciano da questa cartella.

---

## 0.2 — Prendi il token di LocalStack

Da marzo 2026 LocalStack vuole un account anche per la versione gratuita.

1. Registrati su **app.localstack.cloud** — usa la mail della scuola.
2. Se hai il **GitHub Student Developer Pack**: collega l'account GitHub e attiva il **piano studente**. Ti sblocca CodeBuild e CodePipeline, cioè le Fasi 3 e 4.
3. Copia il tuo **Auth Token**.

> **Non riesci a registrarti adesso?** Vai avanti lo stesso: le Fasi 1 e 2 funzionano senza token. Metti `LOCALSTACK_TAG=3.8` dentro `.env` e userai la vecchia immagine libera.

---

## 0.3 — Metti il token nel laboratorio

```bash
cp .env.example .env
```

**COSA FA:** `cp` copia un file. Qui duplica il file di esempio creando il tuo `.env` personale.

**PERCHÉ:** `.env` è il file dove Docker va a leggere le variabili quando accende LocalStack. `.env.example` sta nel repo per far vedere *quali* variabili servono; `.env` è il tuo e contiene il valore vero.

Ora apri `.env` e incolla il token:

```
LOCALSTACK_AUTH_TOKEN=ls-xxxxxxxxxxxxxxxx
```

> **Igiene, non formalità.** `.env` è già dentro `.gitignore`, quindi git lo ignora. Il token è una credenziale: **non finisce mai dentro un commit**. È lo stesso riflesso dello `sniffa-segreti.sh` della L06.

---

## 0.4 — Accendi l'AWS finto

```bash
docker compose up -d
```

**COSA FA:** legge `docker-compose.yml`, scarica l'immagine di LocalStack se non ce l'hai, e avvia il container. L'opzione **`-d`** sta per *detached*: il container gira in sottofondo e ti restituisce il terminale. Senza `-d` il terminale resterebbe occupato dai log.

**PERCHÉ:** quel container è il tuo AWS. Da quando è acceso, c'è qualcosa in ascolto sulla porta **4566** che risponde come risponderebbe AWS.

```bash
docker ps
```

**COSA FA:** elenca i container **in esecuzione** (`ps` = *process status*, come su Linux).

**COSA DEVI VEDERE:** una riga con `localstack-its` e lo stato `Up`.

```bash
curl -s http://localhost:4566/_localstack/health
```

**COSA FA:** `curl` fa una richiesta HTTP e stampa la risposta. **`-s`** = *silent*, toglie la barra di avanzamento. L'indirizzo `/_localstack/health` è una pagina di servizio che elenca i servizi interni e il loro stato.

**PERCHÉ:** `docker ps` ti dice che la scatola è accesa; questo ti dice che il programma **dentro** la scatola è pronto. Non è la stessa cosa: fra i due passano una ventina di secondi.

**COSA DEVI VEDERE:** un JSON con dentro un elenco di servizi (`s3`, `cloudformation`, …).

**SE NON FUNZIONA:** se `curl` non risponde, aspetta 20 secondi e riprova. Se dopo un minuto è ancora muto, guarda i log con `docker compose logs --tail 40`.

---

## 0.5 — Il controllo che decide il tuo binario

```bash
./scripts/00-check.sh
```

**COSA FA:** in ordine — verifica che `docker`, `aws`, `zip` e `jq` siano installati; controlla che LocalStack risponda; prova a chiamare S3, CloudFormation e IAM (i servizi del piano gratuito); prova a chiamare CodeBuild e CodePipeline (quelli del piano studente). Alla fine stampa il verdetto.

**PERCHÉ:** perché su quale binario sei non lo decidi a occhio, e non lo decido io: lo decide quello che l'emulatore risponde davvero.

**COSA DEVI VEDERE:**

| Verdetto | Cosa fai |
|---|---|
| **BINARIO B** (tutto verde) | Fasi 1 → 2 → 3 → 4 |
| **BINARIO A** (piano gratuito) | Fasi 1 → 2 → 3bis |

Le righe gialle `[--]` sui servizi del piano studente **non sono errori**: sono il tuo binario. Le righe rosse `[NO]` invece sì: quelle vanno sistemate prima di andare avanti.

### ✅ Checkpoint Fase 0
`./scripts/00-check.sh` finisce senza righe rosse `[NO]`, e sai se sei su A o su B.

---

# FASE 1 — Pubblicare a mano
**30 minuti · la fanno tutti**

Obiettivo: mettere un sito dentro S3 usando i comandi. E capire, con le dita, **perché non basta**.

---

## 1.1 — Di' all'AWS CLI dove sta il "suo" AWS

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_PAGER=""
```

**COSA FA:** `export` crea una variabile d'ambiente, cioè un valore che tutti i programmi lanciati da questo terminale possono leggere. L'AWS CLI cerca proprio queste quattro.

- `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` sono le credenziali.
- `AWS_DEFAULT_REGION` è la regione: AWS ha decine di data center, ogni richiesta ne nomina uno. All'emulatore non importa quale, ma il CLI la pretende.
- `AWS_PAGER=""` disattiva il paginatore: senza, ogni output lungo si apre dentro `less` e devi premere `q` ogni volta.

**PERCHÉ credenziali finte:** LocalStack accetta qualunque cosa, ma **il CLI si rifiuta di partire senza**: firma ogni richiesta *prima* di sapere chi c'è dall'altra parte. Il controllo è lato client. Per questo scriviamo `test` / `test`.

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

**COSA FA:** `aws` è l'AWS CLI, quello vero. `s3 ls` chiede l'elenco dei bucket. **`--endpoint-url`** dice al CLI a quale indirizzo mandare la richiesta.

**PERCHÉ è il comando più importante della giornata:** è lo **stesso identico binario** che useresti in azienda, con la stessa sintassi. Cambia una cosa sola: dove arriva la richiesta. Il CLI non *sa* con chi sta parlando — sa solo un URL, e si fida.

**COSA DEVI VEDERE:** niente. È corretto: non ci sono ancora bucket.

**SE NON FUNZIONA:** `Could not connect to the endpoint URL` vuol dire che LocalStack non è acceso o non è ancora pronto. Torna al punto 0.4.

```bash
alias awslocal='aws --endpoint-url=http://localhost:4566'
awslocal s3 ls
```

**COSA FA:** `alias` crea una scorciatoia. Da adesso `awslocal` vale come tutto quel pezzo di comando.

**ATTENZIONE:** l'alias vive **solo in questo terminale**. Se ne apri uno nuovo, o se il Codespace si riavvia, lo ricrei.

---

## 1.2 — Crea il bucket e accendilo come sito

```bash
awslocal s3 mb s3://bacheca-its
```

**COSA FA:** `mb` = *make bucket*. `s3://bacheca-its` è l'indirizzo del bucket: `s3://` dice "questo è un bucket", `bacheca-its` è il nome.

**COSA DEVI VEDERE:** `make_bucket: bacheca-its`

**SE NON FUNZIONA:** `BucketAlreadyExists` vuol dire che ce l'hai già. Vai avanti, o cambia nome.

> Hai sbagliato a scrivere il nome? Nessun problema: usa **il tuo** nome per tutto il resto del laboratorio. Anzi, è utile che non siano tutti identici.

```bash
awslocal s3 website s3://bacheca-its --index-document index.html
```

**COSA FA:** accende sul bucket la modalità "sito web statico". **`--index-document`** dice quale file servire quando qualcuno chiede la radice del sito.

**PERCHÉ:** un bucket normale è un magazzino di file. Con questa impostazione diventa un sito: chi apre `/` si vede `index.html` senza doverlo nominare.

**COSA DEVI VEDERE:** nessun output. In Unix, silenzio = è andata bene.

---

## 1.3 — La build

```bash
./build.sh
```

**COSA FA:**

1. cancella `dist/` (parte sempre pulito);
2. copia dentro tutto quello che c'è in `sito/`;
3. calcola un numero di build da data e ora (più il commit git, se c'è);
4. sostituisce il segnaposto `__VERSIONE__` dentro `index.html` con quel numero;
5. scrive `dist/versione.json`.

**PERCHÉ un numero di build:** perché quando guardi il sito online devi poter dire **quale** versione stai guardando. Senza, «ho ricaricato ma non cambia niente» è impossibile da diagnosticare.

**COSA DEVI VEDERE:** quattro righe `[build]`, l'ultima `OK -> dist/ (3 file)`.

> **La regola che vale ovunque:** `sito/` sono i **sorgenti**, li modifichi tu e stanno in git. `dist/` è l'**artefatto**: usa e getta, si rigenera, sta fuori da git. Se modifichi `dist/` invece di `sito/`, **la prossima build cancella il tuo lavoro**. Succede a tutti una volta: che sia oggi, non in azienda.

---

## 1.4 — Pubblica

```bash
awslocal s3 sync dist/ s3://bacheca-its --delete
```

**COSA FA:** `sync` confronta la cartella locale col contenuto del bucket e **carica solo quello che è cambiato**. **`--delete`** toglie dal bucket i file che nella cartella non ci sono più.

**PERCHÉ `--delete`:** senza, il bucket accumula i resti di tutti i deploy precedenti. Rinomini un file e la versione vecchia resta online per sempre, raggiungibile da chi ne conosce l'indirizzo.

**COSA DEVI VEDERE:** tre righe `upload:`.

### Controlli

```bash
awslocal s3 ls s3://bacheca-its
awslocal s3 cp s3://bacheca-its/index.html -
```

**COSA FANNO:** il primo elenca il contenuto del bucket. Il secondo scarica un file — e quel **trattino finale** al posto della destinazione significa "stampalo a schermo invece di salvarlo".

**PERCHÉ così e non col browser:** questa è la lettura *autenticata*, quella che funziona sempre. Per il browser c'è il punto dopo.

---

## 1.5 — Vederlo nel browser

```bash
./scripts/90-anteprima.sh bacheca-its
```

**COSA FA:** scarica in una cartella temporanea quello che c'è **davvero dentro il bucket**, poi avvia un piccolo server web locale sulla porta 8080 che serve quei file.

**PERCHÉ non l'URL "vero" di S3:** su Docker Desktop funziona anche `http://bacheca-its.s3-website.localhost.localstack.cloud:4566`. Dentro un Codespace no: il browser sta su un'altra macchina rispetto all'emulatore. Lo script funziona in **tutti e due i casi**, e per questo usiamo quello.

**COSA DEVI VEDERE:** nel Codespace, scheda **PORTS** in basso → porta **8080** → icona del mondo. Si apre la bacheca.

**SE L'ANTEPRIMA È VUOTA:** nel bucket non è arrivato niente. Il problema è nel passo prima, non qui.

Per fermare il server: `CTRL+C`.

### ✅ Checkpoint Fase 1
Tre file nel bucket, l'HTML stampato a schermo, la bacheca visibile nel browser.

### 🤔 Domanda da scrivere nella consegna (punto 1.5)

> Hai pubblicato in quattro comandi. **Cosa succede se domani li sbagli, li lanci in ordine diverso, o li lancia un collega che oggi non era in aula?**

Due righe in `deliverables/risposte.md`. Rispondi **prima** di leggere la fase dopo.

<details>
<summary>La risposta (aprila dopo aver scritto la tua)</summary>

Il problema non è che sia difficile: è che **non c'è scritto da nessuna parte**.

- La configurazione del bucket vive **solo nella memoria di chi l'ha digitata**.
- Non è in git: nessuno può rivederla, nessuno sa quando è cambiata.
- Non è ripetibile: due persone la rifanno in due modi diversi.
- Se cancelli tutto, ricostruirlo significa **ricordarsi** i comandi.
- Se salti il comando `s3 website`, te ne accorgi quando un utente ti scrive.

Questo è ClickOps travestito da riga di comando. Usare il CLI invece della console non ti rende automatico: ti rende solo più veloce a sbagliare.
</details>

> Sbloccati con: `./scripts/10-fase1-s3.sh`

---

# FASE 2 — Dichiararlo invece che digitarlo
**35 minuti · la fanno tutti**

Stessa identica infrastruttura, ma **scritta in un file**. Se il file è nel repo, l'infrastruttura è versionata, rivedibile e ricostruibile.

---

## 2.1 — Leggi il template prima di lanciarlo

```bash
cat infra/01-sito.yaml
```

**COSA FA:** `cat` stampa un file a schermo.

Tre cose da notare, e sono **tre concetti**, non tre righe:

| Blocco | Cosa fa | Perché conta |
|---|---|---|
| `Parameters` | Dichiara il nome del bucket come valore che arriva da fuori | Stesso template, dieci ambienti diversi |
| `PublicAccessBlockConfiguration` | Spegne il blocco degli accessi pubblici | Su AWS vero, senza questo la policy pubblica **non serve a niente**. È l'errore più comune su S3 |
| `Outputs` | Fa **restituire** allo stack dei valori | Sono quelli che una pipeline legge per sapere dove pubblicare |

---

## 2.2 — Deploy

```bash
awslocal cloudformation deploy \
  --stack-name bacheca \
  --template-file infra/01-sito.yaml \
  --parameter-overrides NomeBucket=bacheca-cfn
```

**COSA FA, opzione per opzione:**

- `cloudformation deploy` crea lo stack se non esiste, lo aggiorna se esiste già;
- `--stack-name bacheca` è il nome con cui lo stack viene registrato: è la chiave con cui lo ritrovi;
- `--template-file` indica il file da applicare;
- `--parameter-overrides NomeBucket=bacheca-cfn` riempie il parametro dichiarato nel template.

La barra rovesciata `\` a fine riga serve solo a spezzare un comando lungo su più righe: la shell le riunisce.

**PERCHÉ:** un comando, da un file, ripetibile. E soprattutto: **da adesso qualcuno tiene il conto** di cosa esiste.

**COSA DEVI VEDERE:**

```
Waiting for changeset to be created..
Waiting for stack create/update to complete
Successfully created/updated stack - bacheca
```

Nota la parola **changeset**: la riprendiamo fra due passi.

---

## 2.3 — Guarda cosa ha creato

```bash
awslocal cloudformation describe-stack-resources --stack-name bacheca \
  --query 'StackResources[].{Risorsa:LogicalResourceId,Tipo:ResourceType,Stato:ResourceStatus}' \
  --output table
```

**COSA FA:** chiede l'elenco delle risorse dello stack.

- **`--query`** è un filtro scritto in **JMESPath**, un linguaggio per pescare dati dentro un JSON. Qui dice: «di ogni risorsa dammi tre campi e chiamali Risorsa, Tipo, Stato».
- **`--output table`** li stampa come tabella invece che come JSON.

**PERCHÉ impararlo:** `--query` ti fa risparmiare ore di `| grep`. È la differenza fra chi usa il CLI e chi lo subisce.

**COSA DEVI VEDERE:** due risorse — il bucket e la sua policy — entrambe `CREATE_COMPLETE`.

```bash
awslocal cloudformation describe-stacks --stack-name bacheca \
  --query 'Stacks[0].Outputs' --output table
```

**COSA FA:** stampa gli `Outputs` dichiarati nel template. `Stacks[0]` significa "il primo (e unico) stack della risposta".

---

## 2.4 — La modifica: qui sta il pezzo importante

Apri `infra/01-sito.yaml` e cambia **una riga**:

```yaml
ErrorDocument: index.html      # prima
ErrorDocument: errore.html     # dopo
```

Poi rilancia **esattamente lo stesso comando** del passo 2.2.

**COSA SUCCEDE:** CloudFormation non ricrea niente da zero. Confronta quello che hai scritto con quello che esiste, calcola la **differenza** e applica solo quella. Il bucket resta lo stesso, con dentro i tuoi file.

### 🤔 Domanda da scrivere nella consegna (punto 2.4)

> Come fa CloudFormation a sapere **cosa esisteva prima**?

<details>
<summary>La risposta (aprila dopo aver scritto la tua)</summary>

Perché **lo stack è uno stato salvato**.

1. Lo stack conserva l'elenco delle risorse che ha creato e com'erano.
2. Al deploy nuovo confronta il template con quello stato.
3. Produce un **changeset**: l'elenco delle differenze.
4. Applica solo quelle.

È lo stesso meccanismo del `terraform plan` visto in UF2: il nome cambia, l'idea no — **prima si guarda cosa cambierebbe, poi si applica**.

E se qualcuno modifica il bucket a mano dalla console, lo stato salvato e la realtà divergono. Quella divergenza si chiama **drift**.
</details>

---

## 2.5 — Pubblica nel bucket nuovo

```bash
./build.sh
awslocal s3 sync dist/ s3://bacheca-cfn --delete
./scripts/90-anteprima.sh bacheca-cfn
```

### ✅ Checkpoint Fase 2
Lo stack è `CREATE_COMPLETE` o `UPDATE_COMPLETE`, e l'anteprima di `bacheca-cfn` mostra la bacheca.

**Nota cosa è rimasto fuori:** l'infrastruttura ora è scritta. Ma **il contenuto** lo pubblichi ancora tu, a mano, quando te lo ricordi. Il processo non è automatico. È il problema della prossima fase.

> Sbloccati con: `./scripts/20-fase2-cloudformation.sh`

---

# FASE 3 — La build in una stanza chiusa
**40 minuti · solo BINARIO B**

> Sei sul **binario A**? Salta alla **Fase 3bis**. Ma leggi comunque il perché qui sotto: vale per tutti.

Fino ad ora la build l'ha fatta **il tuo portatile**. Quindi funziona finché funziona il tuo portatile: la tua versione di bash, le tue variabili, quel file che hai solo tu e non sai di avere. CodeBuild prende il sorgente, lo porta in un **container pulito**, esegue il `buildspec.yml` e ti restituisce l'artefatto. Se funziona lì, funziona per tutti.

---

## 3.1 — Lancia il riscaldamento SUBITO

```bash
./scripts/30-fase3-codebuild.sh
```

**COSA FA, passo per passo** (è la prima volta che ti do lo script prima dei comandi: serve che parta subito):

1. crea i bucket `bacheca-sorgente` e `bacheca-artefatti`;
2. attiva il **versionamento** sul bucket sorgente (`s3api put-bucket-versioning`): serve perché la pipeline possa riferirsi a una versione precisa dello zip;
3. crea il **ruolo di servizio** con `iam create-role` e gli attacca i permessi con `iam put-role-policy`;
4. comprime i sorgenti in `sorgente.zip` (`zip -r` = *recursive*, prende anche le sottocartelle) e lo carica su S3;
5. crea il progetto CodeBuild con `codebuild create-project --cli-input-json`, cioè passando un file JSON invece di venti opzioni sulla riga di comando;
6. lancia la build con `codebuild start-build` e poi controlla lo stato ogni 10 secondi con `batch-get-builds`.

> **LA PRIMA VOLTA È LENTA.** CodeBuild deve scaricare l'immagine del container di build: qualche minuto. Lancialo adesso e **leggi il punto 3.2 mentre scarica**. Non fissare il terminale.

---

## 3.2 — Leggi il buildspec mentre scarica

```bash
cat buildspec.yml
```

| Blocco | Cosa fa |
|---|---|
| `phases.build` | esegue `bash build.sh` → produce `dist/` |
| `phases.post_build` | esegue `bash test.sh` → se un test fallisce, **la build fallisce e l'artefatto non nasce** |
| `artifacts` | dichiara cosa esce dalla stanza chiusa: il contenuto di `dist/` |

**PERCHÉ è lo stesso file della L04:** perché è lo stesso file. Quello che cambia è che ora **gira davvero**, e gira in casa tua, quindi puoi romperlo quanto vuoi.

> ### ⚠️ Crepa numero 1 dell'emulatore
> Dentro LocalStack il blocco **`env:`** del buildspec **non funziona**: le variabili dichiarate lì escono vuote. Su AWS vero funziona. Qui le variabili vanno messe nella definizione del progetto CodeBuild.
>
> Il punto non è la variabile: è che **un ambiente finto ha delle crepe, e tu devi sapere dove sono**. Ne troveremo altre tre. **Segnatele**: la domanda finale della giornata è su questo.

---

## 3.3 — Guarda com'è andata

```bash
awslocal codebuild list-builds-for-project --project-name bacheca-build
```

**COSA FA:** elenca gli ID delle build di quel progetto, dalla più recente.

```bash
awslocal codebuild batch-get-builds --ids <ID-DELLA-BUILD> \
  --query 'builds[0].{Stato:buildStatus,Inizio:startTime,Fine:endTime}'
```

**COSA FA:** chiede i dettagli di una o più build. Si chiama `batch-` perché accetta una lista di ID: qui gliene passi uno solo e con `--query` tieni tre campi.

```bash
awslocal s3 ls s3://bacheca-artefatti --recursive
```

**COSA FA:** elenca il contenuto del bucket degli artefatti. **`--recursive`** entra anche nelle "sottocartelle".

**COSA DEVI VEDERE:** stato `SUCCEEDED` e un file dentro `bacheca-artefatti`.

> ### ⚠️ Crepa numero 2
> LocalStack ti dà **solo lo stato finale**. Su AWS vero vedresti ogni fase — `DOWNLOAD_SOURCE`, `INSTALL`, `BUILD`, `UPLOAD_ARTIFACTS` — con i suoi tempi. Qui no: il troubleshooting fine, qui, non si impara.

---

## 3.4 — Rompila apposta

Apri `sito/index.html` e scrivi la parola **`TODO`** in mezzo al testo. Poi rilancia:

```bash
./scripts/30-fase3-codebuild.sh
```

**PERCHÉ funziona:** uno dei sei controlli di `test.sh` verifica proprio che non restino `TODO` nel sito. Il test fallisce → `test.sh` esce con codice diverso da zero → CodeBuild considera fallita la fase → **l'artefatto non viene prodotto**.

### 🤔 Domanda

> La build è fallita. Cosa è arrivato dentro `bacheca-artefatti`? E cosa è arrivato **sul sito pubblicato**?

Verificalo col comando, non tirarlo a indovinare.

<details>
<summary>La risposta</summary>

**Niente. Ed è tutto il punto.**

L'artefatto non è stato prodotto, quindi non c'era niente da pubblicare, quindi il sito online è rimasto la versione buona di prima.

Il mestiere di una pipeline, in una riga: **impedire che la roba rotta arrivi agli utenti.** Tutto il resto — la velocità, i log, i badge verdi — viene dopo.
</details>

Poi togli il `TODO` e rilancia: torna verde.

### ✅ Checkpoint Fase 3
Una build `SUCCEEDED` con l'artefatto su S3, e una build `FAILED` col `TODO`. **Screenshot di tutte e due**: vanno nella consegna. Quello del fallimento è il più importante dei due.

---

# FASE 3bis — La pipeline la scrivi tu
**40 minuti · solo BINARIO A**

Non hai CodeBuild e CodePipeline. Fai **la stessa identica cosa** con venti righe di bash — e chi scrive l'orchestratore lo capisce meglio di chi lo usa e basta.

```bash
cat scripts/30bis-pipeline-a-mano.sh
./scripts/30bis-pipeline-a-mano.sh bacheca-cfn
```

**COSA FA lo script:** stampa tre intestazioni — `FASE: Sorgente`, `FASE: Build`, `FASE: Deploy` — e fra l'una e l'altra esegue davvero i passi. La regola è nel codice: se `build.sh` o `test.sh` escono con errore, lo script si ferma **prima** del deploy.

Poi metti il `TODO` dentro `sito/index.html` e rilancialo.

### ✅ Checkpoint Fase 3bis
Si ferma alla fase Build, **senza pubblicare niente**, e il sito online resta quello di prima.

### 🤔 Le tre domande (sono il lavoro vero di questa fase)

```bash
cat infra/pipeline.json
```

1. Quali tre stage ha la pipeline e **cosa passa dall'uno all'altro**?
2. Cosa fa CodePipeline che il tuo script bash **non fa**? (almeno tre cose)
3. Nel tuo script, dove si vedrebbe la differenza se **due persone lanciassero il deploy nello stesso momento**?

Risposte in `deliverables/risposte.md`. La terza è la più difficile: pensaci davvero, parla di stato condiviso e di chi vince.

---

# FASE 4 — La pipeline vera
**50 minuti · solo BINARIO B**

Da adesso le tre fasi **non le lanci più tu**.

---

## 4.1 — Leggi la dichiarazione della pipeline

```bash
cat infra/pipeline.json
```

Tre stage, e la cosa da capire sono gli **artifact**:

| Stage | Prende | Fa | Produce |
|---|---|---|---|
| `Sorgente` | lo zip da `s3://bacheca-sorgente` | scarica il codice | `CodiceSorgente` |
| `Build` | `CodiceSorgente` | CodeBuild: build + test | `SitoPronto` |
| `Deploy` | `SitoPronto` | scompatta dentro il bucket | il sito online |

Ogni stage riceve una scatola e ne produce un'altra. I nomi sono le **etichette**.

> ⚠️ **Dove sbagliano tutti la prima volta:** i nomi degli artifact devono **combaciare esattamente**. Se il Build produce `SitoPronto` e il Deploy chiede `sitopronto`, la pipeline non parte e l'errore non è chiarissimo.

**Perché due progetti CodeBuild:** quello della Fase 3 ha `"source": {"type": "S3"}` e va a prendersi il sorgente da solo. Quello della Fase 4 ha `"source": {"type": "CODEPIPELINE"}`: il sorgente **glielo passa la pipeline**, e il progetto non sa né deve sapere da dove arriva. Non è un capriccio di AWS: è separazione delle responsabilità — chi costruisce non decide da dove arriva il codice.

---

## 4.2 — Crea la pipeline

```bash
./scripts/40-fase4-pipeline.sh
```

**COSA FA:** si assicura che il bucket di destinazione esista (rifà il deploy della Fase 2, che è innocuo se è già tutto a posto), crea il progetto CodeBuild in versione pipeline, ricarica il sorgente e infine chiama `codepipeline create-pipeline --pipeline infra/pipeline.json`.

> **Da sapere:** una pipeline **parte da sola appena viene creata**. Non devi lanciarla: quando lo script finisce, sta già girando. Su AWS vero è identico.

---

## 4.3 — Guardala girare

```bash
awslocal codepipeline list-pipeline-executions --pipeline-name bacheca-pipeline
```

**COSA FA:** elenca le esecuzioni della pipeline, con ID e stato complessivo.

```bash
awslocal codepipeline list-action-executions --pipeline-name bacheca-pipeline \
  --query 'actionExecutionDetails[].{Fase:stageName,Azione:actionName,Stato:status}' \
  --output table
```

**COSA FA:** scende di un livello e ti dà **ogni singola azione** con il suo stato, stage per stage. È la vista che usi per capire *dove* si è fermata.

**COSA DEVI VEDERE:** tre righe, tre `Succeeded`. Poi `./scripts/90-anteprima.sh bacheca-cfn`.

**SE VEDI `Failed` SUL BUILD:** quasi sempre è rimasto un `TODO` dalla Fase 3. Il che è un'ottima notizia: vuol dire che la pipeline sta facendo il suo mestiere.

---

## 4.4 — Il ciclo vero: questo è il momento della giornata

1. Apri `sito/index.html` e cambia il testo del secondo avviso.
2. ```bash
   ./scripts/41-rilancia.sh
   ```
   **COSA FA:** rifà lo zip, lo ricarica su S3, chiama `codepipeline start-pipeline-execution` per far ripartire la pipeline, aspetta e alla fine stampa la tabella delle fasi.
3. ```bash
   ./scripts/90-anteprima.sh bacheca-cfn
   ```

**COSA È APPENA SUCCESSO:** il testo nuovo è online e **tu non hai toccato nessun bucket**. Hai toccato il sorgente. Il resto l'ha fatto la pipeline.

Questo è il ciclo di tutti i giorni in azienda: modifichi il codice, lo mandi, e qualcos'altro si occupa di portarlo agli utenti — o di fermarlo.

---

## 4.5 — Rompila un'ultima volta

Rimetti il `TODO` in `sito/index.html` e lancia `./scripts/41-rilancia.sh`. Poi, **senza toccare altro**, apri l'anteprima.

<details>
<summary>Cosa vedi, e perché</summary>

Il sito è **ancora quello buono**. La pipeline si è fermata allo stage `Build`: il Deploy non è mai stato eseguito.

Avete messo del codice rotto nel sorgente e **nessuno se n'è accorto tranne la pipeline**. Gli utenti hanno continuato a vedere la versione buona.

In L01 la domanda era «come faccio a non sbagliare il deploy». La risposta è questa: **non ci si affida a non sbagliare. Si mette in mezzo qualcosa che se ne accorge.**
</details>

### ✅ Checkpoint Fase 4
Screenshot della tabella `list-action-executions` con le tre fasi `Succeeded`, e uno con lo stage `Build` in `Failed`.

---

# Chiusura — dove l'emulatore mente

Un ambiente finto ha sempre delle crepe. **Saperle è la differenza fra un ingegnere e un utente di tool.**

| # | Crepa | Cosa comporta |
|---|---|---|
| 1 | Il blocco `env:` del buildspec non funziona | Il tuo buildspec gira qui e si comporta diversamente su AWS |
| 2 | CodeBuild dà solo lo stato finale | Niente tempi per fase: il troubleshooting fine qui non si impara |
| 3 | I permessi **IAM non vengono applicati davvero** | Qui la pipeline fa tutto. Su AWS potrebbe non averne il diritto |
| 4 | Niente rollback, niente retry di stage, niente pipeline V2 | Tutta la parte «cosa faccio quando va male» qui non c'è |

### 🤔 Domanda finale

> Quale di queste quattro è **la più pericolosa** se ti fidi dell'emulatore e vai in produzione? Motiva.

<details>
<summary>La risposta</summary>

**La numero 3. E non è vicina.**

Le altre tre te le dice l'emulatore: un comando fallisce, un output manca, una feature non c'è. Te ne accorgi qui.

La 3 no: la 3 ti dice che **tutto funziona**, e poi non funziona in produzione. Qui la pipeline scrive nel bucket senza che nessuno controlli i permessi. Su AWS vero il ruolo deve avere `s3:PutObject` su quel bucket, e il bucket deve accettare quel ruolo. Se manca, il deploy fallisce in produzione, di venerdì sera.

Come ci si difende: l'emulatore serve per il **flusso**, non per i permessi. I permessi si provano in un account AWS vero, anche piccolo. E i ruoli minimi si scrivono **da subito**, anche quando qui non servono.

**Un emulatore prova il flusso, non i permessi.** È vera anche fuori da AWS.
</details>

---

## Quello che hai fatto qui, tradotto su AWS vero

| Oggi, in casa | Domani, in azienda |
|---|---|
| `--endpoint-url=localhost:4566` | lo togli. Tutto il resto identico |
| credenziali `test`/`test` | ruoli IAM veri, credenziali temporanee |
| sorgente = zip su S3 | CodeConnections su GitHub: la pipeline parte a ogni push |
| CodeBuild + `buildspec.yml` | **identico** |
| CodePipeline, 3 stage | **identico**, più approvazioni e rollback |
| deploy su S3 | S3, ECS, Lambda, CloudFormation: cambia l'action, non l'idea |

Non hai imparato LocalStack. **Hai imparato CodePipeline, usando LocalStack.**

---

# Consegna

Nella cartella `deliverables/`:

- `risposte.md` compilato — i punti 1.5, 2.4, la domanda finale, e per il binario A le tre domande della Fase 3bis;
- gli screenshot dei checkpoint;
- il tuo `infra/pipeline.json` (o lo script, se sei sul binario A).

```bash
zip -r consegna-COGNOME.zip deliverables/
```

Poi su Moodle. **Una risposta corta e tua vale più di mezza pagina copiata.**

---

# Prima di andare via

```bash
./scripts/99-pulizia.sh      # cancella tutto quello che hai creato dentro LocalStack
docker compose down          # spegne il container
docker compose down -v       # ...e butta anche i dati salvati
```

Se sei su Codespaces, **ferma il Codespace** da `github.com/codespaces`: le ore del piano studente sono tante ma non infinite, e un Codespace acceso e dimenticato se le mangia.

**A casa:** tutto quello che hai fatto oggi si rifà da zero in dieci minuti, gratis. **Rifallo.** È l'unico modo perché resti.

---

# Se qualcosa non va

| Sintomo | Cosa vuol dire | Cosa fare |
|---|---|---|
| `Could not connect to the endpoint URL` | LocalStack spento o non ancora pronto | `docker compose up -d`, aspetta 20 secondi |
| `not included in your current license plan` | Sei sul piano gratuito | Binario A. Tutto normale |
| `command not found: awslocal` | L'alias vale solo nel terminale dove l'hai creato | Ricrea l'alias, o scrivi `aws --endpoint-url=...` per esteso |
| `permission denied: ./scripts/...` | Il file non è eseguibile | `chmod +x scripts/*.sh build.sh test.sh` |
| `docker: command not found` | Sei fuori dal Codespace, o Docker Desktop non è avviato | Controlla dove stai lanciando il comando |
| `BucketAlreadyExists` | Il bucket c'è già | Vai avanti, oppure `./scripts/99-pulizia.sh` |
| La build resta `IN_PROGRESS` per sempre | Sta scaricando l'immagine del container | Aspetta. `docker ps` te lo conferma |
| L'anteprima è vuota | Nel bucket non è arrivato niente | Il deploy è fallito: guarda la fase prima |
| Ho modificato `dist/` e sparisce tutto | `dist/` si rigenera a ogni build | Modifica `sito/`, mai `dist/` |
| Voglio ricominciare da zero | — | `./scripts/99-pulizia.sh`, e se serve `docker compose down -v` |

---

# Appendice — tutti i comandi, in ordine

```bash
# FASE 0 — ambiente
cp .env.example .env                       # poi incolli il token dentro .env
docker compose up -d                       # accende LocalStack
docker ps                                  # il container è su?
curl -s http://localhost:4566/_localstack/health   # il servizio dentro è pronto?
./scripts/00-check.sh                      # verdetto: binario A o B

# FASE 1 — pubblicare a mano
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_PAGER=""
alias awslocal='aws --endpoint-url=http://localhost:4566'
awslocal s3 mb s3://bacheca-its
awslocal s3 website s3://bacheca-its --index-document index.html
./build.sh
awslocal s3 sync dist/ s3://bacheca-its --delete
awslocal s3 ls s3://bacheca-its
./scripts/90-anteprima.sh bacheca-its

# FASE 2 — CloudFormation
cat infra/01-sito.yaml
awslocal cloudformation deploy --stack-name bacheca \
  --template-file infra/01-sito.yaml --parameter-overrides NomeBucket=bacheca-cfn
awslocal cloudformation describe-stack-resources --stack-name bacheca --output table
./build.sh && awslocal s3 sync dist/ s3://bacheca-cfn --delete

# FASE 3 — CodeBuild (binario B)
./scripts/30-fase3-codebuild.sh
cat buildspec.yml
awslocal codebuild list-builds-for-project --project-name bacheca-build
awslocal s3 ls s3://bacheca-artefatti --recursive

# FASE 3bis — pipeline a mano (binario A)
cat scripts/30bis-pipeline-a-mano.sh
./scripts/30bis-pipeline-a-mano.sh bacheca-cfn

# FASE 4 — CodePipeline (binario B)
cat infra/pipeline.json
./scripts/40-fase4-pipeline.sh
awslocal codepipeline list-action-executions --pipeline-name bacheca-pipeline --output table
./scripts/41-rilancia.sh
./scripts/90-anteprima.sh bacheca-cfn

# CHIUSURA
./scripts/99-pulizia.sh
docker compose down
```
