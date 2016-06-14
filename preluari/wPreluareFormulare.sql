/** Atentie: aceasta procedura realizeaza preluare asocierilor vechi de formular (prezente in wIaFormulare hardcodat) in noul tabel
	WebConfigFormulare: este editabil prin macheta Configurare formulare din ASiSria
	*/

IF OBJECT_ID('tempdb..#preluareFormulare') IS NOT NULL
	DROP TABLE #preluareFormulare

CREATE TABLE #preluareFormulare (tipForm VARCHAR(20), tipDoc VARCHAR(20))

INSERT INTO #preluareFormulare (tipDoc, tipForm)
SELECT 'RE', 'J'

UNION

SELECT 'EF', 'J'

UNION

SELECT 'DE', 'J'

UNION

SELECT 'DR', 'J'

UNION

SELECT 'AL', 'J'

UNION

SELECT 'RM', 'R'

UNION

SELECT 'RC', 'R'

UNION

SELECT 'AB', 'J'
-- angajamente bugetare

UNION

SELECT 'AP', 'F'

UNION

SELECT 'AS', 'F'

UNION

SELECT 'IF', 'F'

UNION

SELECT 'FB', 'F'
-- facturi

UNION

SELECT 'AI', 'I'

UNION

SELECT 'AE', 'E'

UNION

SELECT 'CM', 'N'

UNION

SELECT 'PP', 'D'

UNION

SELECT 'BK', 'K'

UNION

SELECT 'BF', 'K'

UNION

SELECT 'FC', 'K'

UNION

SELECT 'FA', 'K'
-- contracte

UNION

SELECT 'FA', 'U'

UNION

SELECT 'II', 'U'

UNION

SELECT 'FM', 'U'

UNION

SELECT 'AV', 'U'

UNION

SELECT 'FT', 'U'
--UA

UNION

SELECT 'BC', 'P'

UNION

SELECT 'RK', 'K'

UNION

SELECT 'BY', 'F'

UNION

SELECT 'SL', '6'

UNION

SELECT 'ME', 'W'

UNION

SELECT 'TH', '`'

UNION

SELECT 'AT', '4'

UNION

SELECT 'RL', '`'
-- machetele din MP sa nu incarce formulare

UNION

SELECT 'DF', 'O'

UNION

SELECT 'CI', 'S'

UNION

SELECT 'PF', 'L'

UNION

SELECT 'AF', 'B'

UNION

SELECT 'OR', 'U'
-- macheta din DP

UNION

SELECT 'MI', 'X'

UNION

SELECT 'ME', 'X'
-- macheta din MF (intrari si iesiri)

UNION

SELECT 'FP', 'M'

UNION

SELECT 'FU', 'M'

UNION

SELECT 'FL', 'M'

UNION

SELECT 'PL', 'M'

UNION

SELECT 'FI', 'M'
-- activitati masini

UNION

SELECT 'RJ', '`'

UNION

SELECT 'SU', '~'

UNION

SELECT 'SI', '`'
-- machetele de date initiale sa nu aiba formulare 

UNION

SELECT 'NC', '9'

UNION

SELECT 'GP', 'J'

UNION

SELECT 'PD', 'Y'

UNION 

SELECT 'TE', 'T'

UNION 

SELECT 'IF', '5'

UNION 

SELECT 'SF', '5'

UNION 

SELECT 'AP', 'A'

UNION 

SELECT 'IB', 'C'

UNION 

SELECT 'IC', 'C'

UNION 

SELECT 'ID', 'C'

--select * from antform a where a.Tip_formular not in 
--(select pf.tipForm from #preluareFormulare pf)

delete webConfigFormulare 
INSERT INTO webConfigFormulare (meniu, tip, cod_formular)
SELECT wtd.meniu, wtd.tip, af.Numar_formular
FROM #preluareFormulare pf
INNER JOIN dbo.wfIaTipuriDocumente(NULL) wtd
	ON wtd.tip = pf.tipDoc
INNER JOIN antform af
	ON af.Tip_formular = pf.tipForm
--GROUP BY wtd.meniu, wtd.tip, af.Numar_formular 
--HAVING COUNT(*)>1