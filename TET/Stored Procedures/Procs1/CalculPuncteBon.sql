-- procedura apelata la descarcarea documentelor PV - calculeaza punctele aferente.
create procedure CalculPuncteBon @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where type='P' and name='CalculPuncteBonSP')
begin
	exec CalculPuncteBonSP @sesiune=@sesiune, @parXML=@parXML
	return
end

declare @msgEroare varchar(500),
	@valoareVanzariBon decimal(12,5), @valoareIncasariPePuncte decimal(12,5), @puncteBon int, @tipVanzare char(1),
	@UID_card varchar(100), @idAntetBon int, @valoarePunctIncasare decimal(12,5), @valoarePunctVanzare decimal(12,5)
set nocount on

begin try
	/* citesc variabile din parXML */
	-- se trimit in XML si casabon numarbon si databon pt. ca trebuie selectat bonul din bp
	select	@idAntetBon = isnull(@parXML.value('(/row/@idAntetBon)[1]', 'int'),0),
			@valoareIncasariPePuncte=0,
			@valoareVanzariBon=0

	select	@UID_card = UID_Card_Fidelizare,
			@valoarePunctIncasare = dbo.wfValoarePunctIncasare(a.Bon),
			@valoarePunctVanzare = dbo.wfValoarePunctVanzare(a.Bon)
		from antetBonuri a 
		where a.idAntetBon=@idAntetBon
		
	-- daca nu s-a facut plata cu card, nu mai fac nimic
	if isnull(@UID_card,'')=''
		return

	-- calculez total vandut pe bon si total incasat pe bon cu metoda de plata 'puncte'
	select @valoareVanzariBon=sum((case when tip='21' then total else 0 end)),
			@valoareIncasariPePuncte= sum((case when tip='37' then total else 0 end)) -- 37 = incasare pe puncte
		from bonuri 
		where idAntetBon=@idAntetBon
	
	-- sterg puncte de pe acelasi bon - in caz ca se refac bonurile, sa nu se dubleze sau sa dea erori
	delete from PvPuncte where IdAntetBon=@idAntetBon
	
	-- tratez daca s-a platit cu puncte
	if abs(@valoareIncasariPePuncte)>0.01 and @valoarePunctIncasare<>0
		insert into PvPuncte(idAntetBon, UID_card, tip, Puncte)
			values(@idAntetBon, @UID_card, 'C', convert(decimal(12,2), @valoareIncasariPePuncte/@valoarePunctIncasare))
	
	-- adaug puncte in functie de produsele vandute
	if abs(@valoareVanzariBon)>0.01 and @valoarePunctVanzare<>0
		insert into PvPuncte(idAntetBon, UID_card, tip, Puncte)
			values(@idAntetBon, @UID_card, 'D', convert(decimal(12,2), @valoareVanzariBon/@valoarePunctVanzare))
	
end try
begin catch
	set @msgEroare = ERROR_MESSAGE()+'(CalculPuncteBon)'
	raiserror(@msgeroare,11,1)
end catch
