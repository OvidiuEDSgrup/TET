--***
create procedure wIaConturiBanca @sesiune varchar(50), @parXML xml
as
begin
	if exists(select * from sysobjects where name='wIaConturiBancaSP' and type='P')
		exec wIaConturiBancaSP @sesiune, @parXML 

	Declare @tert varchar(13), @cautare varchar(200), @fltDenTert varchar(80), @fltDescriere varchar(30)

	select @tert = isnull(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''), 
		@cautare = isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(200)'), '')

	declare @subunitate varchar(9), @AdrPLiv int
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	select @cautare = replace(@cautare, ' ', '%'), 
		@fltDenTert = replace(@fltDenTert, ' ', '%'), 
		@fltDescriere = replace(@fltDescriere, ' ', '%')

--	select * from ContBanci

	select top 100 rtrim(p.tert) as tert, rtrim(t.denumire) as dentert,rtrim(ltrim(p.Banca)) as banca,
		RTRIM(ltrim(p.Cont_in_banca)) as cont_in_banca,Numar_pozitie as numar_pozitie	
	from ContBanci p
		left join terti t on t.tert=p.Tert
	where p.Tert=@tert
		
	for xml raw
end
