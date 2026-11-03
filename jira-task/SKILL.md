---
name: jira-task
description: Tworzy tytuł i opis zadania do Jiry (panele Opis / Kryteria Akceptacji / Kontekst Techniczny) i kopiuje opis do schowka jako sformatowany tekst, który po wklejeniu w Jirę od razu staje się Info panelami. Używaj zawsze, gdy użytkownik wpisze /jira-task, poprosi o "taska do Jiry", "ticket", "zgłoszenie", "opisz to jako zadanie" albo wklei notatki/bug report i chce z nich zrobić zadanie, nawet jeśli nie pada słowo Jira.
---

# jira-task

Zamień surową treść od użytkownika (`/jira-task TREŚĆ`) w zadanie do Jiry: krótki tytuł + opis w trzech kolorowych panelach. Opis trafia do schowka jako HTML, żeby po Cmd+V w edytorze Jiry od razu zrobiły się panele. Zwykły tekst z `{panel}` wkleja się w nowym edytorze Jiry jako surowy tekst, więc go nie używaj.

## Styl: krótko, konkretnie, na temat

Zadanie czyta developer, który chce w 30 sekund wiedzieć, co jest zepsute, kiedy będzie gotowe i gdzie zajrzeć. Dlatego:

- **Opis**: jedno zdanie kontekstu (gdzie i kogo dotyczy), potem punkty z konkretnymi objawami. Bez historii odkrycia błędu, bez "w ramach zadania należy…".
- **Kryteria Akceptacji**: każdy punkt da się sprawdzić tak/nie. Podawaj konkretne wartości, przykładowe teksty komunikatów, daty, kwoty. Jeśli zachowanie zależy od warunków (dzień tygodnia, typ produktu, rola użytkownika), rozpisz scenariusze jako podpunkty: `warunek: oczekiwany wynik`.
- **Kontekst Techniczny**: nazwy plików, klas, metod oraz jedno zdanie, co tam jest nie tak albo czego użyć. Jeśli pracujesz w repozytorium projektu, poszukaj w kodzie miejsc, których dotyczy zadanie (grep po kluczowych słowach), i wpisz prawdziwe nazwy. Nie wymyślaj nazw plików ani metod. Jeśli nie wiesz, gdzie to jest, napisz, co trzeba sprawdzić, albo zostaw jeden punkt "do ustalenia".
- Zwykle 2-5 punktów na sekcję. Nie powtarzaj w kryteriach tego, co jest w opisie, innymi słowami.
- Nie używaj długich myślników (— ani –), także w tytule i estymacji. Zamiast nich zwykły "-", a w zdaniach najlepiej dwukropek, przecinek albo nowe zdanie.
- Język: polski (chyba że treść jest po angielsku). Teksty z UI (komunikaty, napisy, nazwy kroków i przycisków) oraz nazwy plików, klas i metod zapisuj jako inline code (w HTML `<code>…</code>`, w Jirze to monospace z Ctrl+Shift+M) zamiast w cudzysłowach. Jeśli cudzysłów jest naprawdę potrzebny, np. w tytule, gdzie nie ma formatowania, używaj zwykłego "…", nigdy „…” ani “…”.

**Tytuł**: jedno zdanie, do ok. 80 znaków, opisuje problem lub zmianę, bez prefiksów typu "Bug:" (chyba że użytkownik ich używa). Przykład: `Checkout: sprzeczne terminy dostawy na kroku "Dostawa"`.

## Przykład dobrego zadania

Opis
Na kroku `Dostawa` w checkoucie klient widzi sprzeczne informacje o terminie dostawy.
- Zielony komunikat `Dostawa: …` pokazuje datę o 1 dzień późniejszą niż wybrana.
- Brązowy napis obiecuje wysyłkę `dzisiaj` lub `jutro` na podstawie samej godziny 11:00. Nie uwzględnia weekendów ani świąt.

Kryteria Akceptacji
- Zielony komunikat pokazuje dokładnie datę wybraną przez klienta.
- Brązowy napis podaje konkretne daty, np. `Nadanie: poniedziałek 2.11. Najwcześniejsza dostawa: wtorek 3.11.`
- Scenariusze dla koszyka Cold:
  - czwartek przed 11:00: najwcześniejsza dostawa w piątek;
  - sobota lub niedziela: nadanie w poniedziałek.

Kontekst Techniczny
- `shipments.html.twig`: komunikat dodaje +1 dzień w JS.
- `DeliveryDateResolver`: daty do napisu brać z `getEarliestDispatchDate()` i `getEarliestDeliveryDate()`.

## Jak wygenerować wynik

1. Napisz treść zadania według zasad powyżej. Jeśli w TREŚCI brakuje czegoś kluczowego (np. nie wiadomo, jakie ma być oczekiwane zachowanie), napisz zadanie z tym, co jest, a lukę wymień jednym zdaniem w odpowiedzi. Nie zatrzymuj się z pytaniami.
2. Zapisz opis jako HTML do pliku tymczasowego (scratchpad albo `/tmp/jira-task.html`), dokładnie w tej strukturze:

```html
<p><br></p>
<div data-panel-type="info"><p><strong>Opis</strong></p><p>Zdanie kontekstu.</p><ul><li>Komunikat <code>Dostawa: …</code> pokazuje złą datę</li></ul></div>
<div data-panel-type="note"><p><strong>Kryteria Akceptacji</strong></p><ul><li>Kryterium<ul><li>scenariusz</li></ul></li></ul></div>
<div data-panel-type="warning"><p><strong>Kontekst Techniczny</strong></p><ul><li><code>Plik.php</code>: co tam zmienić</li></ul></div>
```

   Typy paneli Jiry odpowiadają kolorom: `info` = niebieski #deebff, `note` = fioletowy #eae6ff, `warning` = żółty #fffae6. Edytor Jiry rozpoznaje `data-panel-type` przy wklejaniu i tworzy z tego Info panel. Escapuj `<`, `>`, `&` w treści.

   Pusty akapit `<p><br></p>` na początku jest potrzebny: edytor Jiry przy wklejaniu łączy pierwszy blok z akapitem pod kursorem, więc bez niego panel "Opis" rozpada się na zwykły tekst. Dzięki temu działa też kopiowanie z pliku otwartego w przeglądarce (Cmd+A, Cmd+C).

3. Skopiuj do schowka:

```bash
bash ~/.claude/skills/jira-task/scripts/copy_html.sh /tmp/jira-task.html
```

   Skrypt wrzuca do schowka wersję HTML (dla Jiry) i wersję tekstową z `{panel}` (zapas dla starego edytora lub pola z wiki markup). Działa tylko na macOS. Jeśli się nie uda, pokaż w czacie wersję z `{panel:bgColor=…}` i powiedz, że kopiowanie nie zadziałało.

## Odpowiedź w czacie

Krótko, w tej kolejności:

1. Tytuł w bloku kodu (żeby dało się go skopiować jednym kliknięciem).
2. Jedna linia: "Opis jest w schowku: w Jirze kliknij pole opisu i wklej (Cmd+V)."
3. Podgląd opisu jako zwykły markdown (nagłówki sekcji + punkty), żeby dało się go przeczytać bez wklejania.
4. Ewentualnie jedno zdanie o lukach z kroku 1.
5. Na końcu estymacja w jednej linii, np. `Estymacja: 2h (z Claude Code). Najwięcej zajmie ręczne sprawdzenie scenariuszy w kalendarzu.`

## Estymacja

Szacuj czas dla developera, który robi zadanie z Claude Code: Claude pisze kod i testy, developer prowadzi, robi review diffu i ręcznie sprawdza zmianę w aplikacji. Samo pisanie kodu jest więc tanie. Czas idzie głównie na zrozumienie problemu, review, ręczne testy scenariuszy z kryteriów i poprawki po nich.

- Używaj skali: 0.5h, 1h, 2h, 4h, 1d, 2d. Przy większych zadaniach zaproponuj w tej samej linii podział na mniejsze.
- Liczba scenariuszy w kryteriach i ręcznego klikania zwykle waży więcej niż liczba plików do zmiany.
- Dolicz czas, gdy przyczyna jest niejasna (trzeba debugować), dochodzi migracja bazy, integracja z zewnętrznym API albo zmiana dotyka checkoutu lub płatności, gdzie regresja jest kosztowna.
- Podaj jedną liczbę i jedno zdanie, co najbardziej wpływa na czas. Bez rozpisywania na etapy.
- Estymacja zostaje w czacie. Nie dodawaj jej do opisu w schowku, bo Jira ma na nią osobne pole.
