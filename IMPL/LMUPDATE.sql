SELECT REPLACE(DENUMIRE,'VANZARI - ','')
FROM LM WHERE Nivel =3 AND Cod_parinte='1VNZAG'

--UPDATE LM 
SET Denumire=REPLACE(DENUMIRE,'VANZARI - ','')
FROM LM WHERE Nivel =3 AND Cod_parinte='1VNZAG'

--UPDATE LM 
SET Denumire=REPLACE(DENUMIRE,'  ',' ')
FROM LM WHERE Nivel =3 AND Cod_parinte='1VNZAG'

--UPDATE LM 
SET Denumire=UPPER(DENUMIRE)
FROM LM WHERE Nivel =4 AND Cod_parinte='1VNZAG'

--UPDATE LM 
SET Nivel=4
FROM LM WHERE Nivel =3 AND Cod_parinte='1VNZAG'

--TRUNCATE table speciflm
--INSERT speciflm 
select
lm.Cod,--Loc_de_munca	char	no	9
'',--Tipul_comenzii	char	no	1
RIGHT(COD,3),--Marca	char	no	6
''--Comanda	char	no	60
FROM LM WHERE Nivel =4 AND Cod_parinte='1VNZAG' 
and cod>'1VNZAG003'