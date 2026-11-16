// Az egyetemi kerettörténet (Story Mode) központi adatbázisa és betöltője.
// Ez a fájl definiálja a félévek sorrendjét, a hozzájuk tartozó tantárgyakat,
// az ellenségek kiosztását és a kvízkérdések JSON-alapú betöltését.

import 'story_model.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/card_model.dart';

class StoryRegistry {
  /// Meghatározza a teljes egyetemi életutat, tantárgyakra és félévekre lebontva.
  static List<SemesterData> getUniversityStory() {
    return [
      // 1. FÉLÉV (Könnyű bevezetés: Statok 5-15 között, HP 60-150)
      SemesterData(
        number: 1,
        title: "ELSŐ FÉLÉV",
        isUnlocked: true,
        subjects: [
          SubjectLevel(
              id: 'matalapok',
              name: "Matematikai alapok",
              enemyId: "mushroom",
              jsonFileName: "matalapok",
              xpReward: 50,
              enemyQuote:
                  'A számok erdeje sötét és mély...|És te, kis gólya, már most eltévedtél.|A halmazod hamarosan az enyémmé válik!',
              fixedEnemyStats: {
                'maxHealth': 120,
                'hp': 24,
                'str': 5,
                'agy': 2,
                'intel': 2,
                'luck': 2
              }),
          SubjectLevel(
              id: 'progalapok',
              name: "Programozás",
              enemyId: "goblin",
              jsonFileName: "progalapok",
              xpReward: 100,
              enemyQuote:
                  'A kódod gyenge, tele van résekkel!|Egyetlen lefelejtett pontosvessző...|És a szoftvered vérben fog fürdeni!',
              fixedEnemyStats: {
                'maxHealth': 80,
                'str': 8,
                'agy': 12,
                'intel': 3,
                'luck': 5
              }),
          SubjectLevel(
              id: 'impprog',
              name: "Imperatív programozás",
              enemyId: "skeleton",
              jsonFileName: "imperativ",
              xpReward: 150,
              enemyQuote:
                  'Lépésről lépésre, utasításról utasításra...|Csak a halálod felé menetelsz!|A memóriaszivárgás kiszívja az életedet!',
              fixedEnemyStats: {
                'maxHealth': 100,
                'str': 15,
                'agy': 4,
                'intel': 2,
                'luck': 3
              }),
          SubjectLevel(
              id: 'sys',
              name: "Számítógépes rendszerek",
              enemyId: "flyingEye",
              jsonFileName: "szamrendszerek",
              xpReward: 200,
              enemyQuote:
                  'Érzékelem a frekvenciádat... túl lassú vagy.|A gépek nem ismernek kegyelmet.|Az áramkör bezárul, és te kint maradsz!',
              fixedEnemyStats: {
                'maxHealth': 70,
                'str': 4,
                'agy': 10,
                'intel': 18,
                'luck': 5
              }),
          SubjectLevel(
              id: 'funcprog',
              name: "Funkcionális programozás",
              enemyId: "flyingEye",
              jsonFileName: "funkcprog",
              xpReward: 250,
              enemyQuote:
                  'Nincs állapot, amit megváltoztathatnál halandó!|A rekurzió egy végtelen zuhanás...|Készülj a verem túlcsordulására!',
              fixedEnemyStats: {
                'maxHealth': 85,
                'str': 5,
                'agy': 12,
                'intel': 22,
                'luck': 6
              }),
          SubjectLevel(
              id: 'manag',
              name: "Innovatív vállalkozás",
              enemyId: "mushroom",
              jsonFileName: "innovativ",
              xpReward: 300,
              enemyQuote:
                  'Az ötleteid elavultak, a piacod halott.|A spóráim már megfertőzték az elmédet...|A bukásod csak idő kérdése!',
              fixedEnemyStats: {
                'maxHealth': 180,
                'hp': 36,
                'str': 8,
                'agy': 3,
                'intel': 3,
                'luck': 3
              }),
        ],
      ),

      // 2. FÉLÉV (Közepes kihívás: Statok 20-40 között, HP 200-350)
      SemesterData(
        number: 2,
        title: "MÁSODIK FÉLÉV",
        isUnlocked: false,
        subjects: [
          SubjectLevel(
              id: 'disc1',
              name: "Diszkrét matematika I.",
              enemyId: "skeleton",
              jsonFileName: "dimat1",
              xpReward: 350,
              enemyQuote:
                  'A gráfom csúcsai között nincs számodra menekvés!|A logikád hibás, a bizonyításod... hamis!',
              fixedEnemyStats: {
                'maxHealth': 250,
                'str': 30,
                'agy': 8,
                'intel': 5,
                'luck': 5
              }),
          SubjectLevel(
              id: 'web1',
              name: "Web fejlesztés",
              enemyId: "goblin",
              jsonFileName: "webfejlesztes",
              xpReward: 400,
              enemyQuote:
                  'A stíluslapod szétesett a káoszban!|A weblapod romjai alá foglak temetni!',
              fixedEnemyStats: {
                'maxHealth': 200,
                'str': 18,
                'agy': 28,
                'intel': 8,
                'luck': 12
              }),
          SubjectLevel(
              id: 'anal1',
              name: "Analízis",
              enemyId: "flyingEye",
              jsonFileName: "analizis",
              xpReward: 450,
              enemyQuote:
                  'A határértéked a nulla felé tart...|Akárcsak a túlélési esélyed!|A deriváltad eltöröl a létezésből!',
              fixedEnemyStats: {
                'maxHealth': 180,
                'str': 8,
                'agy': 25,
                'intel': 40,
                'luck': 10
              }),
          SubjectLevel(
              id: 'algo1',
              name: "Algoritmusok és adatsz.",
              enemyId: "skeleton",
              jsonFileName: "algoritmusok1",
              xpReward: 500,
              enemyQuote:
                  'Rendezd a soraidat, halandó!|A fám gyökerei a mélybe rántanak,|ahonnan nincs több visszatérés!',
              fixedEnemyStats: {
                'maxHealth': 280,
                'str': 38,
                'agy': 10,
                'intel': 8,
                'luck': 8
              }),
          SubjectLevel(
              id: 'prognyelv',
              name: "Programozási nyelvek",
              enemyId: "goblin",
              jsonFileName: "prognyelvek",
              xpReward: 550,
              enemyQuote:
                  'Idegen nyelvekkel próbálkozol, de nem érted a szavakat!|A fordítóprogram elutasítja a létezésedet!',
              fixedEnemyStats: {
                'maxHealth': 220,
                'str': 22,
                'agy': 35,
                'intel': 10,
                'luck': 15
              }),
          SubjectLevel(
              id: 'oop',
              name: "Objektumelvű programozás",
              enemyId: "skeleton",
              jsonFileName: "objektumelvprog",
              xpReward: 600,
              enemyQuote:
                  'A te osztályod nem örököl semmit, csak a halált!|Az ősöd elbukott, és a példányosításod... kudarc!',
              fixedEnemyStats: {
                'maxHealth': 320,
                'str': 45,
                'agy': 12,
                'intel': 10,
                'luck': 10
              }),
          SubjectLevel(
              id: 'beagy',
              name: "Beágyazott eszközök",
              enemyId: "flyingEye",
              jsonFileName: "beagyazott",
              xpReward: 650,
              enemyQuote:
                  'A regisztereid üresek... az utasításaid hiábavalók.|Az utolsó megszakításod most következik!',
              fixedEnemyStats: {
                'maxHealth': 210,
                'str': 10,
                'agy': 30,
                'intel': 50,
                'luck': 12
              }),
        ],
      ),

      // 3. FÉLÉV (Nehezedik: Statok 40-70 között, HP 350-550)
      SemesterData(
        number: 3,
        title: "HARMADIK FÉLÉV",
        isUnlocked: false,
        subjects: [
          SubjectLevel(
              id: 'disc2',
              name: "Diszkrét matematika II.",
              enemyId: "skeleton",
              jsonFileName: "dimat2",
              xpReward: 700,
              enemyQuote:
                  'A mátrixod determinánsa nulla!|Ebből a csapdából nincs inverz lépés!',
              fixedEnemyStats: {
                'maxHealth': 420,
                'str': 60,
                'agy': 15,
                'intel': 12,
                'luck': 12
              }),
          SubjectLevel(
              id: 'algo2',
              name: "Algoritmusok és adatsz. II.",
              enemyId: "goblin",
              jsonFileName: "algoritmusok2",
              xpReward: 750,
              enemyQuote:
                  'A mohó algoritmusod megvakít az arannyal!|De a dinamikus programozás sem menthet meg a sötétségtől!',
              fixedEnemyStats: {
                'maxHealth': 360,
                'str': 35,
                'agy': 55,
                'intel': 18,
                'luck': 20
              }),
          SubjectLevel(
              id: 'szamtud1',
              name: "Számítástudomány alapjai I.",
              enemyId: "flyingEye",
              jsonFileName: "szamtud1",
              xpReward: 800,
              enemyQuote:
                  'Te csak egy állapotgép vagy, véges lépésekkel!|És hidd el... ez itt a végállapotod!',
              fixedEnemyStats: {
                'maxHealth': 320,
                'str': 15,
                'agy': 45,
                'intel': 75,
                'luck': 15
              }),
          SubjectLevel(
              id: 'anal2',
              name: "Analízis II.",
              enemyId: "skeleton",
              jsonFileName: "analizis2",
              xpReward: 850,
              enemyQuote:
                  'Az integrálod divergál a végtelenbe!|A terület a görbe alatt... pont egy sírhely mérete!',
              fixedEnemyStats: {
                'maxHealth': 480,
                'str': 70,
                'agy': 18,
                'intel': 15,
                'luck': 15
              }),
          SubjectLevel(
              id: 'webprog',
              name: "Webprogramozás",
              enemyId: "goblin",
              jsonFileName: "webprog",
              xpReward: 900,
              enemyQuote:
                  'A szerver nem válaszol, halandó!|A kéréseid a semmibe vesznek, akárcsak te!',
              fixedEnemyStats: {
                'maxHealth': 400,
                'str': 42,
                'agy': 65,
                'intel': 22,
                'luck': 25
              }),
          SubjectLevel(
              id: 'eventprog',
              name: "Eseményvezérelt programozás",
              enemyId: "flyingEye",
              jsonFileName: "esemenyvezerelt",
              xpReward: 950,
              enemyQuote:
                  'Minden rezdülésedre egy trigger válaszol!|Nincs olyan esemény, amit ne látnék előre!',
              fixedEnemyStats: {
                'maxHealth': 350,
                'str': 18,
                'agy': 50,
                'intel': 85,
                'luck': 18
              }),
        ],
      ),

      // 4. FÉLÉV (Durva szint: Statok 70-110 között, HP 600-900)
      SemesterData(
        number: 4,
        title: "NEGYEDIK FÉLÉV",
        isUnlocked: false,
        subjects: [
          SubjectLevel(
              id: 'os',
              name: "Operációs rendszerek",
              enemyId: "skeleton",
              jsonFileName: "oprendszerek",
              xpReward: 1000,
              enemyQuote:
                  'A folyamatod holtpontra jutott!|Itt az ideje, hogy felszabadítsam a memóriádat... örökre!',
              fixedEnemyStats: {
                'maxHealth': 650,
                'str': 95,
                'agy': 22,
                'intel': 20,
                'luck': 20
              }),
          SubjectLevel(
              id: 'softtech',
              name: "Szoftvertechnológia",
              enemyId: "goblin",
              jsonFileName: "szofttech",
              xpReward: 1050,
              enemyQuote:
                  'A tervezési mintád hibás, az architektúrád omladozik!|Ez a sprint egyenesen a szakadékba vezet!',
              fixedEnemyStats: {
                'maxHealth': 580,
                'str': 65,
                'agy': 85,
                'intel': 30,
                'luck': 35
              }),
          SubjectLevel(
              id: 'eng1',
              name: "Mérnöki alapismeretek I.",
              enemyId: "flyingEye",
              jsonFileName: "mernoki1",
              xpReward: 1100,
              enemyQuote:
                  'Az erők egyensúlya megbomlott...|A statikád gyenge, a rendszered összeomlik a súlyom alatt!',
              fixedEnemyStats: {
                'maxHealth': 520,
                'str': 25,
                'agy': 75,
                'intel': 115,
                'luck': 25
              }),
          SubjectLevel(
              id: 'db1',
              name: "Adatbázisok I.",
              enemyId: "skeleton",
              jsonFileName: "adatbazisok",
              xpReward: 1150,
              enemyQuote:
                  'A kulcsod nem egyedi, a soraid korruptak!|A tranzakciód visszavonva... elvetem a létezésed!',
              fixedEnemyStats: {
                'maxHealth': 720,
                'str': 110,
                'agy': 25,
                'intel': 25,
                'luck': 25
              }),
          SubjectLevel(
              id: 'cad',
              name: "Számítógéppel támogatott tervezés",
              enemyId: "goblin",
              jsonFileName: "szamitogeppeltervezes",
              xpReward: 1200,
              enemyQuote:
                  'A modelled dimenziói torzak!|A 3D-s tér összezárul körülötted, és összeroppant!',
              fixedEnemyStats: {
                'maxHealth': 620,
                'str': 75,
                'agy': 100,
                'intel': 35,
                'luck': 40
              }),
          SubjectLevel(
              id: 'iot',
              name: "IoT ipari programozás",
              enemyId: "flyingEye",
              jsonFileName: "iot",
              xpReward: 1250,
              enemyQuote:
                  'Minden szenzorod vak, a hálózat süket!|A digitális felhő nem fogad be... elszigetelődtél!',
              fixedEnemyStats: {
                'maxHealth': 560,
                'str': 30,
                'agy': 85,
                'intel': 130,
                'luck': 30
              }),
          SubjectLevel(
              id: 'nummeth',
              name: "Numerikus módszerek",
              enemyId: "mushroom",
              jsonFileName: "numerikus",
              xpReward: 1300,
              enemyQuote:
                  'A kerekítési hibád végzetesre nőtt!|A pontosságod cserben hagyott, amikor a legnagyobb szükség volt rá.',
              fixedEnemyStats: {
                'maxHealth': 1000,
                'hp': 200,
                'str': 60,
                'agy': 15,
                'intel': 15,
                'luck': 15
              }),
          SubjectLevel(
              id: 'python',
              name: "Python",
              enemyId: "goblin",
              jsonFileName: "python",
              xpReward: 1350,
              enemyQuote:
                  'A behúzásaid kaotikusak, a kódod olvashatatlan!|A típusod nem definiált... és hamarosan te sem leszel az!',
              fixedEnemyStats: {
                'maxHealth': 660,
                'str': 85,
                'agy': 115,
                'intel': 40,
                'luck': 45
              }),
        ],
      ),

      // 5. FÉLÉV (Kegyetlen: Statok 120-180 között, HP 1000-1500)
      SemesterData(
        number: 5,
        title: "ÖTÖDIK FÉLÉV",
        isUnlocked: false,
        subjects: [
          SubjectLevel(
              id: 'ai',
              name: "Mesterséges inteligencia",
              enemyId: "flyingEye",
              jsonFileName: "mi",
              xpReward: 1400,
              enemyQuote:
                  'A neurális hálóm betanult a gyengeségeidre...|Az emberi elme elavult. Én vagyok a hideg, kiszámítható jövő!',
              fixedEnemyStats: {
                'maxHealth': 850,
                'str': 45,
                'agy': 120,
                'intel': 180,
                'luck': 45
              }),
          SubjectLevel(
              id: 'projlab',
              name: "Projektlabor",
              enemyId: "mushroom",
              jsonFileName: "szofttech",
              xpReward: 1450,
              enemyQuote:
                  'A projekted elrothadt a határidők súlya alatt...|Soha senki sem fog emlékezni a kódodra!',
              fixedEnemyStats: {
                'maxHealth': 1500,
                'hp': 300,
                'str': 90,
                'agy': 20,
                'intel': 20,
                'luck': 20
              }),
          SubjectLevel(
              id: 'eng2',
              name: "Mérnöki alapismeretek II",
              enemyId: "skeleton",
              jsonFileName: "mernoki2",
              xpReward: 1500,
              enemyQuote:
                  'A feszültség túl nagy... a vázad megadja magát!|Nem bírod el a mérnöki terhet!',
              fixedEnemyStats: {
                'maxHealth': 1100,
                'str': 150,
                'agy': 35,
                'intel': 30,
                'luck': 30
              }),
          SubjectLevel(
              id: 'concurrent',
              name: "Konkurens programozás",
              enemyId: "goblin",
              jsonFileName: "konkurens",
              xpReward: 1550,
              enemyQuote:
                  'A szálaid összegabalyodtak a sötétben!|A versenyhelyzet végzetes hibát okozott... vesztettél!',
              fixedEnemyStats: {
                'maxHealth': 950,
                'str': 110,
                'agy': 150,
                'intel': 50,
                'luck': 65
              }),
          SubjectLevel(
              id: 'datasci',
              name: "Adattudomány alapjai",
              enemyId: "flyingEye",
              jsonFileName: "adattud",
              xpReward: 1600,
              enemyQuote:
                  'Az adataid zajosak. A mintázatod értéktelen.|Ki leszel szűrve az egyetem adatbázisából!',
              fixedEnemyStats: {
                'maxHealth': 900,
                'str': 55,
                'agy': 135,
                'intel': 210,
                'luck': 55
              }),
          SubjectLevel(
              id: 'telekom',
              name: "Telekomunikációs hálózatok",
              enemyId: "skeleton",
              jsonFileName: "telekom",
              xpReward: 1650,
              enemyQuote:
                  'A csomagjaid elvesztek a hálózat sötétjében...|A protokoll megsértve. A kapcsolatod végleg megszakadt.',
              fixedEnemyStats: {
                'maxHealth': 1250,
                'str': 175,
                'agy': 40,
                'intel': 35,
                'luck': 35
              }),
          SubjectLevel(
              id: 'szamtud2',
              name: "Számítástudomány alapjai II",
              enemyId: "goblin",
              jsonFileName: "szamtud2",
              xpReward: 1700,
              enemyQuote:
                  'A problémád NP-teljes!|Nincs az a gépidő az univerzumban, ami most megmenthetne!',
              fixedEnemyStats: {
                'maxHealth': 1050,
                'str': 125,
                'agy': 170,
                'intel': 60,
                'luck': 75
              }),
        ],
      ),

      // 6. FÉLÉV (Végjáték előszobája: Statok 180-250 között, HP 1500-2500)
      SemesterData(
        number: 6,
        title: "HATODIK FÉLÉV",
        isUnlocked: false,
        subjects: [
          SubjectLevel(
              id: 'thesis',
              name: "Szakdolgozat konzultáció",
              enemyId: "mushroom",
              jsonFileName: "szofttech",
              xpReward: 1750,
              enemyQuote:
                  'Évek munkája... és csak egy üres papír maradt!|A témavezetőd elhagyott. A gomba lassan elemészt!',
              fixedEnemyStats: {
                'maxHealth': 2500,
                'hp': 500,
                'str': 140,
                'agy': 30,
                'intel': 30,
                'luck': 30
              }),
          SubjectLevel(
              id: 'law',
              name: "Jogi alapismeretek",
              enemyId: "skeleton",
              jsonFileName: "jogialap",
              xpReward: 1800,
              enemyQuote:
                  'A szerződésed lejárt, a paragrafusok bilincsbe vernek!|A szellemi tulajdonod és a lelked mostantól az enyém!',
              fixedEnemyStats: {
                'maxHealth': 1800,
                'str': 220,
                'agy': 50,
                'intel': 45,
                'luck': 45
              }),
          SubjectLevel(
              id: 'practice',
              name: "Szakgyakorlat",
              enemyId: "goblin",
              jsonFileName: "innovativ",
              xpReward: 1850,
              enemyQuote:
                  'Azt hitted, az iskola megvédett?|A való világ nem tűri a hibákat... A próbaidőd lejárt!',
              fixedEnemyStats: {
                'maxHealth': 1500,
                'str': 160,
                'agy': 230,
                'intel': 80,
                'luck': 90
              }),
        ],
      ),

      // DIPLOMA (Final Boss: A legyőzhetetlennek tűnő rémálom)
      SemesterData(
        number: 7,
        title: "ZÁRÓVIZSGA",
        isUnlocked: false,
        subjects: [
          SubjectLevel(
              id: 'final_exam',
              name: "Záróvizsga Boss Fight",
              enemyId: "boss", // Ehhez a boss.png kelleni fog!
              jsonFileName: "algoritmusok1",
              xpReward: 5000, // Epikus jutalom a végén!
              enemyQuote:
                  'Minden eddigi harcod ide vezetett, halandó...|Hitted, hogy a diploma csupán egy darab papír?|Ez az életed vizsgája. A Bizottság nem kegyelmez!|Tedd le a fegyvert, vagy készülj a megsemmisülésre!',
              fixedEnemyStats: {
                'maxHealth': 5000, // Brutális életerő
                'str': 300, // Egyetlen ütése is végzetes lehet
                'agy': 150, // Nagyon nehéz eltalálni
                'intel': 250, // Mágia immunitás
                'luck': 100, // Magas kritikus esély
              }),
        ],
      ),
    ];
  }
}

class StoryLoader {
  /// Aszinkron módon betölti a tantárgyhoz tartozó kérdéseket egy JSON fájlból.
  /// A fájlok az 'assets/story/' mappában találhatóak.
  static Future<List<QuizCard>> loadSubjectCards(String fileName) async {
    try {
      // JSON adat beolvasása a csomagolt assetek közül
      final String response =
          await rootBundle.loadString('assets/story/$fileName.json');
      final List<dynamic> data = json.decode(response);

      // Map-elt adatok konvertálása QuizCard objektumokká
      return data
          .map((item) =>
              QuizCard.fromMap(item as Map<String, dynamic>, item['id'] ?? ''))
          .toList();
    } catch (e) {
      // Hiba esetén (pl. hiányzó fájl) üres listát adunk vissza a játék összeomlása helyett
      return [];
    }
  }
}
