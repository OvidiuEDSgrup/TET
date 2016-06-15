--***
create function [dbo].[fDateIndicatori]
(
	@codcateg varchar(20),
	@datajos datetime,
	@datasus datetime,
	@lm varchar(13)
)
RETURNS table
AS
RETURN (
	select rtrim(indicatori.cod_indicator) as cod_indicator,rtrim(Denumire_Indicator) as denumire_indicator,
	indicatori.Expresie as expresie,
	RTRIM(isnull(expval.Tip,'E')) as tipdate,
	convert(decimal(12,2),sum(expval.Valoare)) as ef,
	convert(decimal(12,2),sum((case when month(expval.data)=1 then expval.Valoare else 0 end))) as l01,
	convert(decimal(12,2),sum(case when month(expval.data)=2 then expval.Valoare else 0 end)) as l02,
	convert(decimal(12,2),sum(case when month(expval.data)=3 then expval.Valoare else 0 end)) as l03,
	convert(decimal(12,2),sum(case when month(expval.data)=4 then expval.Valoare else 0 end)) as l04,
	convert(decimal(12,2),sum(case when month(expval.data)=5 then expval.Valoare else 0 end)) as l05,
	convert(decimal(12,2),sum(case when month(expval.data)=6 then expval.Valoare else 0 end)) as l06,
	convert(decimal(12,2),sum(case when month(expval.data)=7 then expval.Valoare else 0 end)) as l07,
	convert(decimal(12,2),sum(case when month(expval.data)=8 then expval.Valoare else 0 end)) as l08,
	convert(decimal(12,2),sum(case when month(expval.data)=9 then expval.Valoare else 0 end)) as l09,
	convert(decimal(12,2),sum(case when month(expval.data)=10 then expval.Valoare else 0 end)) as l10,
	convert(decimal(12,2),sum(case when month(expval.data)=11 then expval.Valoare else 0 end)) as l11,
	convert(decimal(12,2),sum(case when month(expval.data)=12 then expval.Valoare else 0 end)) as l12
	from indicatori
	inner join compcategorii on indicatori.Cod_Indicator=compcategorii.Cod_Ind
	left outer join expval on expval.Tip in ('E','P') and indicatori.Cod_Indicator=Expval.Cod_indicator 
		and Expval.Data between @datajos and @datasus and (@lm='' or Expval.Element_1=@lm)
	where compcategorii.Cod_Categ=@codcateg
	group by rtrim(indicatori.cod_indicator),rtrim(Denumire_Indicator),indicatori.Expresie,RTRIM(isnull(expval.Tip,'E'))
	)
