# Consegna — AWS in casa

**Nome e cognome:** ESTHER WANJIRU NGUMO
**Binario seguito:** A (piano gratuito) / B (piano studente)

---

## 1.5 — Pubblicare a mano

> Hai pubblicato in quattro comandi. Cosa succede se domani li sbagli, o se li lancia
> un tuo collega in ordine diverso?


_(risposta)_
Publishing by hand is not enough since the steps exist only in my memory and this terminal. They are not in git, so nobody can review them or repeat them. If I forget a command, or a colleague does it differently, the site breaks and I'd only find out when a user hits it.


---

## 2.4 — Il changeset

> Cosa e' cambiato quando hai rilanciato il deploy dopo aver modificato ErrorDocument?
> Perche' CloudFormation non ha ricreato il bucket?

_(risposta)_
A changeset is the list of differences CloudFormation calculates between my template and the state it already has saved. It applies only those differences, so changing one line updates one property instead of recreating everything.

---

## Fase 3 / 4 — Binario B

> Incolla qui lo stato delle tre fasi della pipeline (output di list-action-executions)
> e allega gli screenshot.

_(risposta)_

> Quando hai messo il TODO, dove si e' fermata la pipeline e cosa e' rimasto online?

_(risposta)_

---

## Fase 3bis — Binario A

1. Quali tre stage ha la pipeline e cosa passa dall'uno all'altro?

_(risposta)_

2. Cosa fa CodePipeline che il tuo script bash non fa? (almeno tre cose)

_(risposta)_

3. Dove si vedrebbe la differenza se due persone lanciassero il deploy nello stesso momento?

_(risposta)_

---

## Chiusura — Dove l'emulatore mente

> Delle quattro crepe viste a lezione, quale e' la piu' pericolosa se ti fidi
> dell'emulatore e vai in produzione? Motiva.

_(risposta)_
