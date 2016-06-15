--***
-- Procedura apartine machetei de configurare categorii de indicatori (Ghita, 27.04.2011)
-- trebuie trecuta de pe tabela "indicatori" pe tabela "compcategorii"

CREATE procedure wIaIndicatoriCategorie @sesiune varchar(50), @parXML XML 
as

declare @flt_cod varchar(15), @flt_denumire varchar(25), @flt_expresie varchar(100), @codCat varchar(20),
		@rand decimal(5,2), @parinte varchar(10)

select @flt_cod = rtrim(isnull(@parXML.value('(/row/@f_cod)[1]', 'varchar(15)'), '')),
	@flt_denumire = rtrim(isnull(@parXML.value('(/row/@f_denumire)[1]', 'varchar(25)'), '')),
	@flt_expresie = rtrim(isnull(@parXML.value('(/row/@f_expresie)[1]', 'varchar(10)'), '')),
	@codCat= rtrim(isnull(@parXML.value('(/row/@codCat)[1]', 'varchar(10)'), '')),
	@rand= isnull(@parXML.value('(/row/@rand)[1]', 'decimal(5,2)'), 0),
	@parinte= rtrim(isnull(@parXML.value('(/row/@parinte)[1]', 'varchar(10)'), ''))


if @parXML.value('(/row/@_cautare)[1]', 'varchar(25)') is not null
	set @flt_denumire=isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(25)'),'')

set @flt_cod='%'+REPLACE(@flt_cod,' ','%')+'%'
set @flt_denumire= '%'+REPLACE(@flt_denumire,' ','%')+'%'
set @flt_expresie='%'+REPLACE(@flt_expresie,' ','%')+'%'
set @codCat=@codCat
set @rand=REPLACE(@rand,' ','%')
set @parinte=REPLACE(@parinte,' ','%')

select rtrim(Cod_Indicator) as cod, rtrim(Denumire_Indicator) as denumire , rtrim(expresia) as expresie, 
	(case when Ordine_in_raport  =1 then 'Da' else 'Nu' end) as cuData ,
	(case when unitate_de_masura= '0' then 'Linie' when unitate_de_masura='1' then 'Placinta' when unitate_de_masura='2' then 'Coloane' else 'Ceas' end) as tipgrafic,
	c.Rand as rand
from indicatori i 
inner join compcategorii c on i.Cod_Indicator=c.Cod_Ind
where
	Cod_Indicator like @flt_cod and
	Denumire_indicator like @flt_denumire and
	expresia like @flt_expresie and
	c.Cod_Categ=@codCat
for xml raw
