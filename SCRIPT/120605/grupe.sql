TRUNCATE TABLE grupeidx
insert grupeidx
select DISTINCT
CASE CATEG_CONTABILA 
	WHEN 'Marfuri' THEN CASE WHEN GRUPA_VANZARE LIKE '%pachet%' THEN 'P' ELSE 'M' END 
	WHEN 'Promotionale' THEN 'M' WHEN 'Piese schimb' THEN 'M' ELSE '' END--Tip_de_nomenclator	char	no	1	     
,LEFT((SELECT MAX(CODGRUPAVANZARE) FROM GRUPE_VANZARE WHERE GRUPA_VANZARE LIKE NOM_CATEG.GRUPA_VANZARE),13)--Grupa	char	no	13	     
,LEFT(GRUPA_VANZARE,120)--Denumire	char	no	30	     
,0--Proprietate_1	bit	no	1	     
,0--Proprietate_2	bit	no	1	     
,0--Proprietate_3	bit	no	1	     
,0--Proprietate_4	bit	no	1	     
,0--Proprietate_5	bit	no	1	     
,0--Proprietate_6	bit	no	1	     
,0--Proprietate_7	bit	no	1	     
,0--Proprietate_8	bit	no	1	     
,0--Proprietate_9	bit	no	1	     
,0--Proprietate_10	bit	no	1	     
-- select * 
from import..nom_categ

select MAX(len(description_mf))
from import..nom_categ

select * from import..NOM_CATEG 
where len(description_mf)>30

insert grupe
select * from grupeidx

SELECT * FROM GRUPE
UPDATE grupe
SET Tip_de_nomenclator='M'
WHERE Tip_de_nomenclator='A'
AND Grupa NOT IN (SELECT Grupa FROM grupe WHERE Tip_de_nomenclator='M')


INSERT grupeidx
select DISTINCT
'M'--Tip_de_nomenclator	char	no	1	     
,LEFT(CODGRUPAVANZARE,13)--Grupa	char	no	13	     
,LEFT(GRUPA_VANZARE,120)--Denumire	char	no	30	     
,0--Proprietate_1	bit	no	1	     
,0--Proprietate_2	bit	no	1	     
,0--Proprietate_3	bit	no	1	     
,0--Proprietate_4	bit	no	1	     
,0--Proprietate_5	bit	no	1	     
,0--Proprietate_6	bit	no	1	     
,0--Proprietate_7	bit	no	1	     
,0--Proprietate_8	bit	no	1	     
,0--Proprietate_9	bit	no	1	     
,0--Proprietate_10	bit	no	1	     
-- select * 
from GRUPE_VANZARE
WHERE CODGRUPAVANZARE NOT IN (SELECT GRUPA FROM grupeidx)

TRUNCATE TABLE GRUPE
INSERT GRUPE
SELECT * FROM grupeidx