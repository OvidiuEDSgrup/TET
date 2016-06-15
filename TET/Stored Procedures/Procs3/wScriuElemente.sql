--***
create procedure wScriuElemente @sesiune varchar(50),@parXML XML
as
declare @eroare varchar(1000),@utilizatorASiS varchar(50)
set @eroare=''
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	declare @cod varchar(20), @denumire varchar(60),
			@tip varchar(1), @tipInterval varchar(1), --@denTipInterval varchar(50), 
			@valoare decimal(20,2),@um varchar(3),
			@update int,
			@o_cod varchar(20), @o_tip varchar(1), @o_tipInterval varchar(1)
	select	@cod=isnull(@parXML.value('(row/@cod)[1]','varchar(20)'),''),
			@denumire=isnull(@parXML.value('(row/@denumire)[1]','varchar(60)'),''),
			@tip=isnull(@parXML.value('(row/@tip)[1]','varchar(1)'),''),
			@tipInterval=isnull(@parXML.value('(row/@tipInterval)[1]','varchar(1)'),''),
			--@denTipInterval=isnull(@parXML.value('(row/@denTipInterval)[1]','varchar(50)'),''),
			@valoare=isnull(@parXML.value('(row/@valoare)[1]','decimal(20,2)'),0),
			@um=isnull(@parXML.value('(row/@um)[1]','varchar(3)'),''),
			@update=isnull(@parXML.value('(row/@update)[1]','int'),0),
			@o_cod=isnull(@parXML.value('(row/@o_cod)[1]','varchar(20)'),''),
			@o_tip=isnull(@parXML.value('(row/@o_tip)[1]','varchar(1)'),''),
			@o_tipInterval=isnull(@parXML.value('(row/@o_tipInterval)[1]','varchar(1)'),'')
	if (@cod='') raiserror('Completati codul elementului!',16,1)
	if (@tip='') raiserror('Alegeti tipul elementului!',16,1)
	if (@tipInterval='') raiserror('Alegeti tipul de activitate!',16,1)
	if (@update=1)
	begin
		if (@cod<>@o_cod)
				raiserror('Nu este permisa modificarea codului elementului!',16,1)
		if (@tip<>@o_tip)
				raiserror('Nu este permisa modificarea tipului elementului!',16,1)
		if (@tipInterval<>@o_tipInterval)
				raiserror('Nu este permisa modificarea tipului de activitate!',16,1)
		update e set e.Denumire=@denumire, e.Interval=@valoare,e.UM=@um,
			e.um2=@tipInterval	--> daca e configurat gresit UM2 (cum ar fi Act in loc de A) s-ar corecta asa
			from elemente e where e.Cod=@o_cod
	end
	else
	begin
		if exists (select 1 from elemente e where e.Cod=@cod) 
			raiserror('Exista deja un element operat cu acelasi cod!',16,1)
			select @tipInterval
		insert into elemente(Cod, Denumire, Tip, UM, UM2, Interval)
		select @cod, @denumire, @tip, @um, @tipInterval, @valoare
	end
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wScriuElemente)'
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
