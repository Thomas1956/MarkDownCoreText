# Markdown‑Parser Dokumentation

Diese Datei beschreibt, welche Markdown‑Syntax der App‑interne Parser versteht, welche app‑eigenen Erweiterungen es gibt und welche Parameter sich über die Einstellungen steuern lassen.

Der Parser baut auf Apples `Foundation.AttributedString`‑Markdown‑Parsing auf (CommonMark‑kompatibel) und erweitert es um eigene Inline‑Konstrukte, eine YAML‑Stirn (Front Matter) für PDF‑Metadaten sowie einen eigenen Block‑Renderer, der mit Core Text gesetzt wird.

---

## 1. Standard‑Markdown

### Überschriften

```
# Überschrift 1
## Überschrift 2
### Überschrift 3
#### Überschrift 4
##### Überschrift 5
###### Überschrift 6
```

- ATX‑Style (`#` … `######`) mit allen sechs Ebenen.
- Größen sind geräteabhängig (iPhone, iPad, Mac); siehe `Markdown.fontSizes`.
- Vor/nach Überschriften gibt es automatische Abstände; folgen mehrere Überschriften unmittelbar aufeinander, wird der Vorabstand reduziert.

### Hervorhebung

| Syntax | Wirkung |
|---|---|
| `*kursiv*` oder `_kursiv_` | kursiv |
| `**fett**` oder `__fett__` | fett |
| `***fett & kursiv***` | fett kursiv |
| `~~durchgestrichen~~` | Strikethrough |
| `` `inline code` `` | Monospace, ca. 85 % der Body‑Größe |

### Absätze, Zeilenumbrüche, Trennlinien

- **Absatz**: durch Leerzeile getrennt.
- **Soft Break**: zwei Leerzeichen am Zeilenende erzeugen einen Umbruch ohne neuen Absatz (`useSoftBreaks` muss aktiv sein).
- **Trennlinien**: `---`, `***` oder `___` auf einer eigenen Zeile. Gerendert als horizontale Linie, Aussehen siehe Sektion **Ruler** der Settings.

### Listen

```
- ungeordnet
* auch ungeordnet
+ ebenfalls

1. geordnet
2. weiter
   1. eingerückte Unterliste
```

- Bullet‑Symbole je Schachtelung: `•`, `⚬`, `⁃`.
- **Aufgabenliste**: `- [ ]` (offen), `- [x]` (erledigt) – wird als SF‑Symbol gerendert (`square`, `checkmark.square`).

### Links

```
[Apple](https://www.apple.com)
<email@example.com>
```

- `<email@…>` wird automatisch zu `[email@…](mailto:email@…)` aufgelöst.
- Im PDF werden Links als anklickbare Annotationen registriert.

### Bilder

```
![alt](image.png)
![alt](image.png:24)
![alt](image.png:24x30)
![alt](image.png:24, color: 'systemRed')
```

Quellen werden in dieser Reihenfolge gesucht:

1. Asset‑Catalog (`UIImage(named:)`).
2. Im in den Einstellungen gewählten Bilder‑Ordner.
3. SF‑Symbol (`UIImage(systemName:)`).
4. **Nicht auflösbar:** roter Platzhalter `photo.badge.exclamationmark` (siehe Sektion **Fehlende Bilder**).

Remote‑URLs (`http://`, `https://`) werden derzeit **nicht** geladen.

### Code

````
```swift tab4
let x = 1
print(x)
```
````

- Fenced Code Blocks mit optionalem Sprach‑Hint.
- Im Sprach‑Hint kann `tab4` oder `tab8` angegeben werden, um die Tab‑Weite im Code‑Block zu setzen.
- Es findet Syntax‑Highlighting statt (`IdentifierPalette.json`).

### Blockzitate

```
> Ein Zitat
> über mehrere Zeilen
```

- Verschachtelung mit Listen und anderen Blöcken möglich.
- Erscheinungsbild (Balken, Hintergrund) über die Sektion **Block** der Settings steuerbar.

### Tabellen

```
| Spalte 1 | Spalte 2 | Spalte 3 |
|:---------|:--------:|---------:|
| links    | Mitte    | rechts   |
| …        | …        | …        |
```

- Pipe‑Tables nach CommonMark.
- Ausrichtung pro Spalte über die Trennzeile: `:---`, `:---:`, `---:`.
- Rahmen aus Unicode‑Boxzeichen; Spaltenfarbe, Header‑Farbe und Rahmen‑Gewicht über die Sektion **Tabelle** der Settings.

### Inline‑HTML (Mini‑Konverter)

Wenige HTML‑Tags werden vor dem Parsen in Markdown übersetzt:

| HTML | wird zu |
|---|---|
| `<strong>x</strong>`, `<b>x</b>` | `**x**` |
| `<em>x</em>`, `<i>x</i>` | `*x*` |
| `<span style="color: …">x</span>` | `^[x](color: '…')` |
| `<br>` | Soft Break (zwei Leerzeichen + `\n`) |
| `<div>`, `<p>` | Wrapper entfernt |

Komplexere HTML‑Konstrukte werden nicht unterstützt.

---

## 2. Sonderfunktionen / App‑eigene Syntax

### `^[Text](Modifier: 'Wert', …)` — Inline‑Attribute

Eigene Inline‑Auszeichnung mit Schlüssel/Wert‑Paaren. Hängt **nicht** vom umgebenden Markdown ab, lässt sich also auch innerhalb von Listen, BlockQuotes etc. einsetzen.

Unterstützte Modifier:

| Modifier | Werte |
|---|---|
| `color` / `tint` | Asset‑Name, Hex (`'#FF0000'`), System‑Farben (`'systemRed'`, `'systemBlue'`, `'systemGray2'` …), CSS‑Namen (`'red'`, `'blue'` …), abgeleitete (`'label'`, `'secondaryLabel'`, `'systemBackground'` …) |
| `size` | Schriftgröße in Punkten, z. B. `22` |
| `weight` | `'light'`, `'regular'`, `'medium'`, `'semibold'`, `'bold'`, … |
| `style` | `'marked'` (visuelle Markierung) |

Beispiele:

```
Dies ist ^[wichtig](color: 'systemRed').
^[Lorem ipsum](size: 22, weight: 'bold', color: 'orange')
30 IF N = 0 ^[THEN](style: 'marked') 99
```

### `::` — Doppelspalte / Tabulator

Erzeugt aus einem Absatz eine zweispaltige Anzeige. Das `::` wird intern durch einen Tabulator ersetzt; ein Tab‑Stop wird automatisch gesetzt.

```
Linke Spalte:: Rechte Spalte
Name::Position
Datum::2026‑06‑22
```

Optional kann die Tab‑Position als Zahl in einem zweiten `::`‑Paar angegeben werden:

```
Linke Spalte::140:: Rechte Spalte
```

Tab‑Position wird zum aktuellen `headIndent` addiert und mit dem Skalierungsfaktor (`MarkdownTypography.scale`) verrechnet. Default 100 pt at ref. Soft Breaks im selben Block werden zu Absatzsepratoren, damit der Tab pro Zeile wirkt.

`::` ist nicht aktiv innerhalb von Code‑Blöcken, Tabellen und Trennlinien.

### YAML‑Frontmatter für PDF‑Footer

Beginnt das Dokument mit einer Zeile `---`, wird der Block bis zum nächsten `---` als Metadaten gelesen. Aktuell ausgewertet werden Footer‑Einstellungen für PDF‑Export.

Flache Schreibweise:

```yaml
---
pdfFooterLeft:   "Mein Dokument"
pdfFooterCenter: "Seite {page} von {pages}"
pdfFooterRight:  "{date}"
---

# Eigentliches Markdown beginnt hier
```

Strukturierte Schreibweise:

```yaml
---
pdfFooter:
  left:   "Mein Dokument"
  center: "Seite {page} von {pages}"
  right:  "{date}"
---
```

`footer:` ist als Alias zu `pdfFooter:` erlaubt; ebenso `footerLeft`/`footerCenter`/`footerRight` als Alias zu den flachen Keys. Anführungszeichen sind optional, `null`, `nil`, `~` setzen den Eintrag auf nichts.

Platzhalter im Footer‑Text: `{page}`, `{pages}`, `{date}`.

### Definition Lists

```
Begriff
: Definition, erste Zeile
: Definition, zweite Zeile
```

- Begriff wird in `.semibold` gesetzt.
- Definitionen sind um 20 pt (skaliert) eingerückt.

---

## 3. Settings (Parameter im Einstellungen‑Popover)

Alle Werte werden im CoreData‑Model `Settings` persistiert. Längenangaben in Pt beziehen sich auf die Referenz‑Schriftgröße; sie werden zur Laufzeit über `MarkdownTypography.scale` proportional zur aktuellen Body‑Schriftgröße umgerechnet.

### Anzeige (`ViewSetting`)

| Einstellung | Typ | Einheit | Default | Bedeutung |
|---|---|---|---|---|
| Textgröße | Double | Pt | 17 | Basis‑Schriftgröße im LiveView |
| Textfarbe | UIColor | — | `.black` | globale Textfarbe |
| Linker Rand | Double | Pt | 0 | linker Dokumentrand (LiveView) |
| Rechter Rand | Double | Pt | 0 | rechter Dokumentrand (LiveView) |
| Soft Breaks | Bool | — | true | `  \n` als Zeilenumbruch erlauben |
| Silbentrennung | Bool | — | true | automatische Trennung mit Soft Hyphens |
| Blocksatz | Bool | — | false | Text und BlockQuote in Blocksatz |
| Zeilenabstand | Double | × | 1.1 | Multiplikator für Zeilenhöhe |
| Absatzabstand | Double | em | 0.5 | Abstand nach Absätzen |
| Absatzabstand davor | Double | em | 1.2 | Abstand vor Überschriften |

### PDF (`PdfSetting`)

| Einstellung | Typ | Einheit | Default | Bedeutung |
|---|---|---|---|---|
| Textgröße | Double | Pt | 12 | Schriftgröße im PDF |
| Rand links | Double | cm | 2 | linker Seitenrand |
| Rand rechts | Double | cm | 2 | rechter Seitenrand |
| Rand oben | Double | cm | 2 | oberer Seitenrand |
| Rand unten | Double | cm | 2 | unterer Seitenrand |
| Seitenformat | CGRect | cm | A4 (21 × 29,7) | Seitenfläche |
| Footer‑Skalierung | Double | × | 0,8 | Footer‑Schrift relativ zu Body |

### Tabelle (`TableSetting`)

| Einstellung | Typ | Einheit | Default | Bedeutung |
|---|---|---|---|---|
| Einzug links | Double | Pt | 0 | zusätzlicher linker Tabellen‑Einzug |
| Einzug rechts | Double | Pt | 0 | zusätzlicher rechter Tabellen‑Einzug |
| Gitterfarbe | UIColor | — | `.systemGray4` | Linien zwischen Zellen |
| Gitterfarbe ableiten | Bool | — | true | aus Textfarbe statt explizit |
| Header‑Hintergrund | UIColor | — | `.systemGray5` | Kopfzeilen‑Hintergrund |
| Header‑BG ableiten | Bool | — | true | aus Textfarbe statt explizit |
| Tabellen‑Hintergrund | UIColor | — | `.systemGray6` | Body‑Hintergrund |
| Tabellen‑BG ableiten | Bool | — | true | aus Textfarbe statt explizit |
| Zellschrift | UIFont.Weight | — | `.regular` | Gewicht in Zellen |
| Header‑Schrift | UIFont.Weight | — | `.bold` | Gewicht im Header |
| Rahmen‑Gewicht | UIFont.Weight | — | `.ultraLight` | Strichdicke der Boxzeichen |

### Block (BlockQuote) (`BlockQuoteSetting`)

| Einstellung | Typ | Einheit | Default | Bedeutung |
|---|---|---|---|---|
| Block‑Einzug links | Double | Pt | 0 | Abstand der Box vom linken Rand |
| Block‑Einzug rechts | Double | Pt | 0 | Abstand der Box vom rechten Rand |
| Balken‑Innenabstand | Double | Pt | 5 | Abstand Box‑Kante → Balken |
| Balken‑Breite | Double | Pt | 6 | Strichdicke des Balkens |
| Innenabstand links | Double | Pt | 20 | Balken → Text |
| Innenabstand rechts | Double | Pt | 10 | Text → rechter BG‑Rand |
| Vertikaler Offset | Double | Pt | 5 | Box leicht nach unten verschieben |
| Balkenfarbe | UIColor | — | `.systemGray4` | Farbe des Balkens |
| Balkenfarbe ableiten | Bool | — | true | aus Textfarbe statt explizit |
| Hintergrundfarbe | UIColor | — | `.systemGray6` | Box‑Hintergrund |
| BG‑Farbe ableiten | Bool | — | true | aus Textfarbe statt explizit |

### Code (`CodeBlockSetting`)

| Einstellung | Typ | Einheit | Default | Bedeutung |
|---|---|---|---|---|
| Schriftgrößen‑Faktor | Double | % | 95 | Code‑Schrift relativ zu Body |
| Zeilenabstand | Double | × | 1,1 | Zeilenabstand im Code‑Block |
| Abstand davor | Double | Pt | 6 | Abstand vor dem Block |
| Abstand danach | Double | Pt | 6 | Abstand nach dem Block |
| Block‑Einzug links | Double | Pt | 0 | Box‑Einzug links |
| Block‑Einzug rechts | Double | Pt | 0 | Box‑Einzug rechts |
| Innenabstand links | Double | Pt | 10 | Box‑Rand → Code |
| Innenabstand rechts | Double | Pt | 10 | Code → rechter BG‑Rand |
| Hintergrundfarbe | UIColor | — | `.systemGray6` | Box‑Hintergrund |
| BG‑Farbe ableiten | Bool | — | true | aus Textfarbe statt explizit |
| Rahmenfarbe | UIColor | — | `.systemGray4` | Linie um die Box |
| Rahmenfarbe ableiten | Bool | — | true | aus Textfarbe statt explizit |
| Rahmenbreite | Double | Pt | 1 | Strichdicke der Rahmenlinie |

### Ruler (`RulerSetting`)

| Einstellung | Typ | Einheit | Default | Bedeutung |
|---|---|---|---|---|
| Innenabstand links | Double | Pt | 0 | linker Textrand → Linie |
| Innenabstand rechts | Double | Pt | 0 | Linie → rechter Textrand |
| Höhe | Double | Pt | 10 | Höhe des Hintergrundes |
| Linienstärke | Double | Pt | 1,5 | Strichdicke der Linie |
| Farbe | UIColor | — | `.systemGray4` | Linienfarbe (wenn nicht abgeleitet) |
| Aus Textfarbe ableiten | Bool | — | true | Farbe abgeleitet aus Textfarbe |

### Bilder‑Ordner

- **Ordner wählen** öffnet den Document‑Picker; der gewählte Pfad wird als Security‑Scoped Bookmark abgelegt.
- **Löschen** entfernt diese Wahl. Danach werden nur noch Asset‑/SF‑Symbol‑Bilder aufgelöst; lokale Markdown‑Bildreferenzen erscheinen als roter Platzhalter (siehe **Fehlende Bilder**).
- Beim Öffnen einer `.md`, in der lokale Bildreferenzen vorkommen und kein Ordner gesetzt ist, fragt die App per Dialog nach einem Ordner. Picker startet im Verzeichnis der `.md`.

---

## 4. Einzüge & Abstände — Übersicht

Alle Werte werden über `MarkdownTypography.scaled(_)` skaliert.

### Horizontale Einzüge (Absatz / Liste)

```
[linker Bildschirm‑/Seitenrand]
│
│◄── viewMarginLeft / pdfMarginLeft (cm im PDF, Pt im LiveView)
│
│        ◄── firstLineHeadIndent ──►
│        •  Erste Zeile eines Listeneintrags
│        │
│        │   ◄── headIndent (Position der Folgezeilen) ──►
│        │   Diese Zeile wandert an die headIndent‑Position
│        │   und bleibt dort bis zum Absatzende
│        │
│                                                            │
│                              viewMarginRight ──────────────│
│                                                            │
[rechter Rand]
```

- `firstLineHeadIndent`: Position der ersten Zeile (bei Listen die Bullet‑Position).
- `headIndent`: Position der Folgezeilen (bei Listen die Textposition nach dem Bullet).
- `tailIndent`: negativer Abstand vom rechten Rand (Werte werden negativ gespeichert).
- Effektive linke Position = `viewMarginLeft + Listen‑Hierarchie · Bulletbreite + (block‑spezifischer Einzug)`.

### Vertikale Abstände

```
┌─────────────────────────────────────────┐
│            Absatz n‑1                   │
└─────────────────────────────────────────┘
     ▲
     │  paragraphSpacing (nach Absatz n‑1)
     ▼
     ▲
     │  paragraphSpacingBefore (vor Header / BlockQuote)
     ▼
┌─────────────────────────────────────────┐
│   Absatz n   Zeile 1                    │
│   ▲▲                                    │
│   ││  lineSpacing / lineHeightMultiple  │
│   ▼▼                                    │
│   Absatz n   Zeile 2                    │
└─────────────────────────────────────────┘
```

### BlockQuote — Aufbau

```
[linker Rand]
│
│◄── viewMarginLeft ──►│
│                      │
│                      │◄── blockIndentLeft ──►│
│                      │                       │
│                      │            ┌──────────┼──────────────────────────────────┐
│                      │            │ blockBackgroundColor                       │
│                      │            │          │                                 │
│                      │            │ ◄blockBarIndent►│██│◄ blockPaddingLeft ►    │
│                      │            │                 │██│ Text Zeile 1           │
│                      │            │                 │██│ Text Zeile 2           │
│                      │            │  blockBarWidth─┘  │                         │
│                      │            │                   │                         │
│                      │            │              ◄ blockPaddingRight ►          │
│                      │            └────────────────────────────────────┬────────┘
│                      │                                                 │
│                      │                            ◄── blockIndentRight ──►│
│                                                                          │
[rechter Rand]
```

- `blockIndentLeft` / `blockIndentRight`: Abstand der **Box** vom Dokumentrand.
- `blockBarIndent`: Abstand von der Box‑Kante zum linken Balken.
- `blockBarWidth`: Strichdicke des Balkens.
- `blockPaddingLeft`: Abstand vom Balken zum Text.
- `blockPaddingRight`: Abstand vom Text zur rechten Box‑Kante.
- `blockVerticalOffset`: vertikale Verschiebung der Box.

### Code‑Block — Aufbau

```
[linker Rand]
│◄── viewMarginLeft ──►│
│                      │◄── codeIndentLeft ──►│
│                      │                      ┌──────────────────────────────────────┐
│                      │                      │ Rahmen (codeBorderColor/‑Width)      │
│                      │                      │                                      │
│                      │                      │ ◄ codePaddingLeft ►| code line 1     │
│                      │                      │                    | code line 2     │
│                      │                      │              ◄ codePaddingRight ►    │
│                      │                      └──────────────────────────────────────┘
│                      │                                              │◄ codeIndentRight ►│
│                                                                                          │
[rechter Rand]
```

### Ruler — Aufbau

```
│◄── rulerPaddingLeft ──►│  ════ Linie (rulerLineHeight) ════  │◄── rulerPaddingRight ──►│
                         │                                     │
                         │◄────── Rechteck der rulerHeight ───►│
```

### Tabelle — Mindestmaße & Padding

- `tableIndentLeft` / `tableIndentRight`: zusätzlicher Außen‑Einzug der Tabelle, additiv zu `viewMarginLeft/Right`.
- `contentIndent` (intern in `Markdown.Block`): Basis für Padding innerhalb der Zellen und Code‑Blöcke.
- `minimumColumnWidth` und `minimumRowHeight` werden aus skalierten Default‑Werten und der größten Inhalts­dimension bestimmt.

---

## 5. Sonstiges

### Silbentrennung

- Aktiviert über `useHyphenation`.
- Sprache: Standard `de‑DE`.
- Implementierung in `Markdown+Hyphenation.swift`. Soft Hyphens (`\u{00AD}`) werden eingefügt und nur am tatsächlichen Zeilenumbruch als sichtbarer Bindestrich gezeichnet.
- Markdown‑Auszeichnungen wie `(color: '…')` und HTML‑Entities werden nicht getrennt.

### Schriftgrößen‑Skalierung

- `MarkdownTypography.scale = bodyFont.pointSize / referenceBodySize`.
- Pt‑Werte aus den Settings werden zur Laufzeit damit multipliziert — die Eingaben sind also faktisch „Pt bei Referenzgröße" (entspricht semantisch `em × referenceBodySize`).
- Bei größerer Body‑Schrift werden Einzüge, Tab‑Stops und Block‑Padding proportional größer.

### Fehlende Bilder

Wenn eine Bildreferenz weder als Asset noch als SF‑Symbol noch im gewählten Bilder‑Ordner gefunden wird, rendert der Parser ein **rotes Warn‑Symbol** an gleicher Stelle:

- Symbol: `photo.badge.exclamationmark`, Fallback `photo`.
- Standard‑Farbe: `.systemRed`. Eine im Markdown gesetzte `color:` schlägt durch.
- Größe respektiert ein im Markdown angegebenes `:size`.
- Der Platzhalter erscheint sowohl im LiveView **als auch im PDF** – Fehler sollen nicht übersehen werden.

### LiveView vs. PDF — Unterschiede

| Aspekt | LiveView | PDF |
|---|---|---|
| Schriftgröße | `viewTextSize` (Default 17 pt) | `pdfTextSize` (Default 12 pt) |
| Seitenfläche | Spaltenbreite des Splits | A4 (21 × 29,7 cm), konfigurierbar |
| Seitenränder | `viewMarginLeft/Right` (Pt) | `pdfMarginLeft/Right/Top/Bottom` (cm) |
| Footer | – | aus YAML‑Frontmatter |
| Links | im View interaktiv | als PDF‑Annotation |
| Skalierungs‑Referenz | LiveView‑Body | PDF‑Body |

### Wichtige Quellen im Code

| Bereich | Datei(en) |
|---|---|
| Parser‑Einstieg, Frontmatter, HTML‑Konverter | `MarkdownParser.swift` |
| Inline‑Attribute, Listen, Tabellen, Doppelspalte `::` | `MarkdownParser+BlockContent.swift` |
| Block‑Rendering (Bilder, Listen, BlockQuote, Code, Tabelle) | `MarkdownParser+BlockRenderer.swift` |
| Presentation Intents (CommonMark‑Strukturen) | `MarkdownParser+PresentationIntent.swift` |
| Schrift‑/Skalen‑Logik | `MarkdownTypography.swift`, `MarkdownParser+Font.swift` |
| Bilder/Attachments | `MarkdownParser+ImageAttachment.swift` |
| Silbentrennung | `Markdown+Hyphenation.swift` |
| Defaults / Konstanten | `MarkdownParser+Statics.swift` |
| Bilder‑Ordner‑Auflösung | `ViewController/MarkdownImageLocation.swift` |
