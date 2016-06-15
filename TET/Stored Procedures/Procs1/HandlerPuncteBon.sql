--***
create procedure [dbo].[HandlerPuncteBon] @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where type='P' and name='HandlerPuncteBonSP')
begin
	exec HandlerPuncteBonSP @sesiune=@sesiune, @parXML=@parXML
	return
end

declare @CasaBon int, @DataBon datetime, @Numarbon int, @vanzbon varchar(10), @UID varchar(50), @GestBon varchar(13), @msgEroare varchar(500),
	@valoareVanzariBon decimal(12,5), @valoareIncasariPePuncte decimal(12,5), @valoarePunct decimal(12,5), @puncteBon int, @tipVanzare char(1),
	@tert varchar(13)
set nocount on

begin try
	/* citesc variabile din parXML */
	select	@CasaBon = @parXML.value('(/row/@casaM)[1]', 'int'),
			@DataBon = @parXML.value('(/row/@dataBon)[1]', 'datetime'),
			@Numarbon = @parXML.value('(/row/@nrBon)[1]', 'int'),
			@UID = @parXML.value('(/row/@UID)[1]', 'varchar(50)'),
			@GestBon = @parXML.value('(/row/@gestiune)[1]', 'varchar(50)'),
			@vanzbon= @parXML.value('(/row/@vanzator)[1]', 'varchar(50)'),
			@valoareIncasariPePuncte=0,
			@valoareVanzariBon=0

	exec luare_date_par 'PV', 'VALPUNCT', 0, @valoarePunct output, ''
	
	-- calculez total vandut pe bon si total incasat pe bon cu metoda de plata 'puncte'
	select @valoareVanzariBon=(case when tip='21' then total else 0 end),
		@valoareIncasariPePuncte= (case when tip='37' then total else 0 end),
		@tert=bp.Client
	from bp 
	where Casa_de_marcat=@CasaBon and data=@DataBon and Numar_bon=@Numarbon and Vinzator=@vanzbon and Client<>''
	
	-- sterg puncte de pe acelasi bon - in caz ca se refac bonurile, sa nu se dubleze sau sa dea erori
	if exists (select 1 from PvPuncte where tert=@tert and casa_de_marcat=@CasaBon and data=@DataBon and numar_bon=@Numarbon and Utilizator=@vanzbon)
		delete from PvPuncte where tert=@tert and casa_de_marcat=@CasaBon and data=@DataBon and numar_bon=@Numarbon and Utilizator=@vanzbon
	
	-- tratez daca s-a platit cu puncte
	if abs(@valoareIncasariPePuncte)>0.01
		insert into PvPuncte(tert, casa_de_marcat, Data, Numar_bon, Utilizator, tip, Puncte)
			values(@tert, @CasaBon, @DataBon, @Numarbon, @vanzbon, 'C', convert(int,floor(@valoareIncasariPePuncte/@valoarePunct)))
	
	-- adaug puncte in functie de produsele vandute
	if abs(@valoareVanzariBon)>0.01
		insert into PvPuncte(tert, casa_de_marcat, Data, Numar_bon, Utilizator, tip, Puncte)
			values(@tert, @CasaBon, @DataBon, @Numarbon, @vanzbon, 'D', convert(int,floor(@valoareVanzariBon/@valoarePunct)))
	
end try
begin catch
	set @msgEroare = ERROR_MESSAGE()+'(HandlerPuncteBon)'
	raiserror(@msgeroare,11,1)
end catch
