CREATE FUNCTION [dbo].[wfIaArboreConturi]
(
    @cont varchar(40), @f_perioada datetime
)
RETURNS XML
AS
BEGIN
RETURN
 (select	rtrim(re.cont) as cont
				, rtrim(re.cont)+' - '+rtrim(max(ce.Denumire_cont))as contden
				, rtrim(max(ce.Denumire_cont)) as denCont 
				, MAX(ce.nivel) as nivel
				, isnull(rtrim(max(lme.Cod)),'')as lm, isnull(rtrim(max(lme.Denumire)),'') as denlm
				, rtrim(convert(decimal(15,2),sum(re.Rulaj_credit))) as rulajCredit
				, rtrim(convert(decimal(15,2),sum(re.rulaj_debit))) as rulajDebit
				, CONVERT(char(10),re.data,101) as data
				, (case when RTRIM(re.Valuta)='EUR' then 'EUR' else 'RON' end) as valuta
				, RTRIM(case when max(convert(int,ce.Are_analitice))=1 then 'gray' else 'blue' end) as culoare
				, rtrim(max(convert(int,ce.Are_analitice))) as areAnalitice
				, (case when max(convert(int,ce.Are_analitice))=1 then '' else  'MC' end) as subtip
				, CONVERT(xml, dbo.wfIaArboreConturi(rtrim(re.cont), @f_perioada ))
				
		from rulaje re 
		inner join conturi ce on ce.Cont = re.Cont and ce.Cont_parinte = @cont 
		left outer join lm lme on lme.Cod=re.Loc_de_munca
		where re.Data=dbo.eom(@f_perioada) 
		group by re.cont, data, re.Loc_de_munca, re.Valuta
		order by re.Cont asc
		for xml raw, type)
END
