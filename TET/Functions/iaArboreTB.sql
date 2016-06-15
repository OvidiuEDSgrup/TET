--***
create FUNCTION [dbo].[iaArboreTB]
(
    @codcateg varchar(20),
    @codindicator varchar(20),
    @datajos datetime,
    @datasus datetime,
    @lm varchar(13)
)
RETURNS XML
AS
BEGIN
	--Daca se cere bugetul pe loc de munca si locul de munca e nimic plus nu exista nivel mai jos
	if @lm='' and not exists(select 1 from compcategorii
			inner join indicatori on indicatori.Cod_Indicator=compcategorii.Cod_Ind 
			where compcategorii.Cod_categ=@codcateg and compcategorii.Parinte=@codindicator)
		RETURN (select 'CB' as tip,'CB' as subtip,
			rtrim(@codindicator)+'-LM:'+rtrim(lm.cod) as cod_indicator,rtrim(lm.Denumire) as denumire_indicator,
			0 as expresie,
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
			from lm
			left outer join expval on expval.Tip in ('E','P') and Expval.Cod_indicator=@codindicator
				and Expval.Data between @datajos and @datasus and Expval.Element_1=@lm
			group by lm.cod,lm.denumire,RTRIM(isnull(expval.Tip,'E'))
			for xml raw,type)

		--Cazul clasic
		RETURN(select 'CB' as tip,(case when ind.expresie=0 and ind.tipdate='P' then 'CB' else '' end) as subtip,
			ind.*
			,convert(xml,dbo.iaArboreTB(@codcateg,compcategorii.Cod_Ind,@datajos,@datajos,@lm))
			from compcategorii
			inner join dbo.fdateindicatori(@codcateg,@datajos,@datasus,@lm) ind on ind.Cod_Indicator=compcategorii.Cod_Ind
			where compcategorii.Cod_categ=@codcateg and compcategorii.Parinte=@codindicator
			for xml raw,type
			)
END
