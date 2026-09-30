# Consegna — AWS in casa

**Nome e cognome:** ESTHER WANJIRU NGUMO
**Binario seguito:** B (piano studente)
**Ambiente:** locale — MacBook Pro Intel (2020), Docker Desktop + LocalStack.
In Codespaces mi ero fermata alla build per mancanza di disco: l'immagine di CodeBuild occupa 28 GB.

---

## 1.5 — Pubblicare a mano

> Hai pubblicato in quattro comandi. Cosa succede se domani li sbagli, o se li lancia
> un tuo collega in ordine diverso?

Publishing by hand is not enough since the steps exist only in my memory and this terminal. They are not in git, so nobody can review them or repeat them. If I forget a command, or a colleague does it differently, the site breaks and I'd only find out when a user hits it.

---

## 2.4 — Il changeset

> Cosa e' cambiato quando hai rilanciato il deploy dopo aver modificato ErrorDocument?
> Perche' CloudFormation non ha ricreato il bucket?

A changeset is the list of differences CloudFormation calculates between my template and the state it already has saved. It applies only those differences, so changing one line updates one property instead of recreating everything.

---

## Fase 3 / 4 — Binario B

### Fase 3 — CodeBuild da solo

- Build `bacheca-build:9580d12f`: **SUCCEEDED**, artifact in `bacheca-artefatti` → `screenshots/fase3-succeeded.png`
- Same build with a `TODO` in `sito/index.html`: **FAILED**. No new artifact: the files in `bacheca-artefatti` kept the timestamp of the good build (17:00:02) → `screenshots/fase3-failed.png`

My very first build stayed `IN_PROGRESS` forever. From the logs: LocalStack checked the build container 10 seconds after `StartBuild`, while the 7 GB image was still downloading, got `Container not yet started`, and its watcher thread crashed. The build then ran fine (`Exited (0)`), but nobody updated the status. Once the image was downloaded, the next build finished in about 20 seconds.

### Fase 4 — la pipeline (esecuzione più recente in alto)

```
|  CompilaETesta|  Build     |  Failed     |   <- run with TODO: stops here
|  PrendiLoZip  |  Sorgente  |  Succeeded  |
|  PubblicaSuS3 |  Deploy    |  Failed     |   <- clean run: LocalStack bug
|  CompilaETesta|  Build     |  Succeeded  |
|  PrendiLoZip  |  Sorgente  |  Succeeded  |
```

Source and Build worked in every run. **Deploy failed every time** with:

```
Invalid type for parameter Key, value: style.css,
type: <class 'pathlib._local.PosixPath'>, valid types: <class 'str'>
```

My diagnosis: the destination bucket `bacheca-cfn` existed (created by CloudFormation one minute before), so the problem is not my setup. LocalStack's S3 deploy code passes each file name to `PutObject` as a Python path object instead of a string, and the validation rejects it. I also tried `"Extract": "false"` with an `ObjectKey`: LocalStack ignored the setting and failed on `style.css` again. On real AWS this deploy works. → `screenshots/fase4-deploy-bug-localstack.png`

> Quando hai messo il TODO, dove si e' fermata la pipeline e cosa e' rimasto online?

It stopped at **Build** (`Failed`). For that run there is no Deploy row at all: the Deploy stage never started, so broken code never got near the website → `screenshots/fase4-todo-build-failed.png`.
Nothing changed online. Because of the emulator bug, `bacheca-cfn` never received any version in my runs, so it stayed as it was. On real AWS it would have kept showing the last good version.

---

## Fase 3bis — Binario A

Non applicabile: ho seguito il binario B.

---

## Chiusura — Dove l'emulatore mente

> Delle quattro crepe viste a lezione, quale e' la piu' pericolosa se ti fidi
> dell'emulatore e vai in produzione? Motiva.

**Number 3: IAM permissions are not really enforced.** The other cracks show themselves: a command fails, an output is missing, a feature doesn't exist. Crack 3 is silent: everything works here, and then in production the pipeline's role lacks `s3:PutObject` on the bucket and the deploy fails, maybe on a Friday evening. The emulator tests the flow, not the permissions, so permissions must be tested on a real AWS account and minimal roles written from the start.

My own run proved the difference. I hit cracks the lab doesn't list (the S3 deploy bug, the ignored `Extract` setting, and CodeBuild saving loose files instead of `sito-pronto.zip`). Those were annoying but **safe**, because I could see them fail and read the error. Crack 3 would never show an error here at all, and that is what makes it the dangerous one.
