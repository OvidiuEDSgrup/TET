--***
/* functia ia utilizatorul ASiS curent. Se cauta in sesiunea de lucru(daca se trimite), altfel din host_id (ASiS 9.4&ASiSplus), altfel prin SUSER_NAME() */
create function fIaUtilizator (@sesiune varchar(50))
returns varchar(254)
as
begin
	declare @Utilizator varchar(50)
	
	-- identificare user din sesiune - specific ASiSria. 
	-- toate aplicatiile noi dezvoltate, ar trebui sa foloseasca o sesiune. Daca nu exista, se va insera o sesiune in tabela sesiuni.
	if isnull(@sesiune,'')!=''
	begin
		select top 1 @Utilizator=utilizator
		from [$(ASiSria)].dbo.sesiuniRIA 
		where token=@sesiune and BD=DB_NAME() /* validare bd  */
		-- nu returnez cu isnull - toate aplicatiile care au sesiune, trebuie sa foloseasca un user valid.
		return @utilizator
	end

	-- aici se ajunge daca @sesiune e null
	-- pt. asisplus: identificare user folosind host_id() - daca app. name='asisria', nu caut dupa host_id()
	if exists (select 1 from sysobjects where name='sysunic') and charindex('Asisria', APP_NAME())=0
		select top 1 @Utilizator=rtrim(utilizator) from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc

	if left(APP_NAME(),8)='ASiSria\' -- incepand cu ASiSria v2.3.10, sesiunea se trimite si in app name
	begin
		set @sesiune = substring(APP_NAME(), 9,LEN(APP_NAME()))
		if LEN(@sesiune)>0
			return dbo.fIaUtilizator(@sesiune)
	end
	-- legacy - nu stiu daca se mai identifica asa din vreun loc 
	-- eventual din aplicatii specifice care se vor lega la server cu user SQL specific(ex. AW)
	if @Utilizator is null and exists (select 1 from sysobjects where name='utilizatori')
		select @Utilizator=rtrim(id) from utilizatori where observatii=SUSER_name()
	-- legacy: trimit user cu isnull pentru cazurile in care se apeleaza din ASiSplus sau din SQL Management Console...
	return isnull(@utilizator,'')
end
