USE [TET]
GO
/****** Object:  StoredProcedure [dbo].[wiaformulare]    Script Date: 02/20/2012 16:31:42 ******/
DROP procedure [dbo].[wIaFormulareSP]
GO
CREATE procedure [dbo].[wIaFormulareSP] @sesiune varchar(40),@parXML xml
as    
declare @utilizator varchar(255),@formimplicit varchar(255),@tip varchar(10)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
select	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')
		
/* citesc ultimul formular folosit din proprietati. Folosesc tip ='PROPUTILIZ', nu 'UTILIZATOR' pt. ca 
vreau sa nu se vada in ED la proprietati pe utilizator */
select @formimplicit=Valoare
from proprietati p where p.Tip='PROPUTILIZ' and p.Cod_proprietate='FORM'+@tip and p.cod=@utilizator

if exists(select * from sysobjects where name='wIaFormulareSP' and type='P' and SCHEMA_NAME(uid)='yso')        
 exec yso.wIaFormulareSP @sesiune,@parXML
else        
begin 
	select rtrim(a.Numar_formular) as formular,    
	RTRIM(Denumire_formular) as denumire,(case when @formimplicit=a.numar_formular then 0 else 1 end) as ordonare  
	from antform a --inner join XMLFormular x on x.Numar_formular=a.Numar_formular and x.Nume_fisier=null
	where Tip_formular=(case @tip when 'RE' then 'J' when 'EF' then 'J' when 'DE' then 'J' 
	when 'AL' then 'J' when 'AB' then 'J' -- angajamente bugetare
	when 'AP' then 'F' when 'AS' then 'F' when 'IF' then '5' when 'FB' then 'F' -- facturi
	when 'AI' then 'I' when 'AE' then 'E' when 'CM' then 'N' when 'PP' then 'D' 
	when 'BK' then 'K' when 'BF' then 'K' when 'FC' then 'K' when 'FA' then 'K' -- contracte
	when 'FA' then 'U' when 'II' then 'U' when 'FM' then 'U' when 'AV' then 'U' when 'FT' then 'U'--UA
	when 'BC' then 'P' when 'RK' then '' when 'BY' then 'F' when 'SL' then '6' when 'ME' then 'W' 
	when 'TH' then '`' when 'AT' then '4' when 'RL' then '`' -- machetele din MP sa nu incarce formulare
	when 'DF' then 'O' when 'CI' then 'S' when 'PF' then 'L' when 'AF' then 'B' 
	when 'OR' then 'U'  -- macheta din DP
	when 'MI' then 'X' when 'ME' then 'X'  -- macheta din MF (intrari si iesiri)
	when 'FP' then 'M' when 'FU' then 'M' when 'FL' then 'M' when 'PL' then 'M' when 'FI' then 'M' -- activitati masini
	when 'RJ' then '`' when 'SU' then '~' when 'SI' then '`' -- machetele de date initiale sa nu aiba formulare 
	when 'NC' then '9' when 'GP' then 'J' else Tip_formular end) 
	--and eXML=1 and x.continut is not null
	and eXML=1 and exists (select * from xmlformular x where x.numar_formular=a.numar_formular and x.continut is not null)    
	order by 3,2  
	for xml raw
end