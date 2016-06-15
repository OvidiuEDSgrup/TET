--***
create procedure [dbo].[wIaFacturiTerti] @sesiune varchar(30), @parXML XML
as
if exists(select * from sysobjects where name='wIaFacturiTertiSP' and type='P')
	exec wIaFacturiTertiSP @sesiune, @parXML 
else 
begin
	Declare @iDoc int

	Declare @cSub varchar(9), @tert varchar(20), @cautare varchar(100)
	
	exec luare_date_par 'GE','SUBPRO',1,0,@cSub OUTPUT
	
	Set @tert = @parXML.value('(/row/@tert)[1]','varchar(20)')
	Set @cautare = @parXML.value('(/row/@_cautare)[1]','varchar(100)')

	select
		(case when s.Tip=0x46 then 'B' else 'F' end) as tip, rtrim(s.Factura) as numar, convert(char(10),s.data,101) as data,
		convert(char(10),s.Data_scadentei,101) as datascadentei, convert(decimal(12,2),s.valoare) as valoare,
		convert(decimal(12,2),s.tva_22+s.tva_11) as TVA,
		CONVERT ( decimal (12,2), s.Achitat) as achitat, convert(char(10),s.Data_ultimei_achitari ,101) as dataachitarii, 
		convert(decimal(12,2),s.sold) as sold, RTRIM(s.Cont_de_tert) as cont, rtrim(s.Loc_de_munca) as lm,
		valuta, convert(decimal(10,4),curs) as curs, convert(decimal(12,2),Sold_valuta) as soldvaluta
	from facturi s
	where s.Subunitate = @cSub and s.tert = @tert 
		and abs(s.Sold) > 0.001
		and (isnull(@cautare,'')='' or s.Factura like '%'+@cautare+'%')
	union all
	select
		rtrim(e.Tip) as tip, rtrim(e.Nr_efect) as numar, convert(varchar(10), e.Data, 101) as data,
		convert(varchar(10), e.Data_scadentei, 101) as datascadentei, convert(decimal(12,2), e.Valoare) as valoare,
		null as TVA, convert(decimal(12,2), e.Decontat) as achitat, convert(varchar(10), e.Data_decontarii, 101) as dataachitarii,
		convert(decimal(12,2), e.Sold) as sold, rtrim(e.Cont) as cont, rtrim(e.Loc_de_munca) as lm,
		rtrim(e.Valuta) as valuta, convert(decimal(10,4), e.Curs) as curs, convert(decimal(12,2), e.Sold_valuta) as soldvaluta
	from efecte e
	where e.Subunitate = @cSub and e.Tert = @tert
		and abs(e.Sold) > 0.001
		and (isnull(@cautare, '') = '' or e.Nr_efect like '%' + @cautare + '%')
	order by Data desc
	for xml raw

end
