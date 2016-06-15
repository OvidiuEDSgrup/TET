-- 
create procedure wIaPuncteCardFidelizare @sesiune varchar(50), @parXML XML as
if exists (select 1 from sysobjects where type='P' and name='wIaPuncteCardFidelizareSP')
begin
	exec wIaPuncteCardFidelizareSP @sesiune=@sesiune, @parXML=@parXML
	return
end

begin try
	declare @UID_Card varchar(50), @puncte int, @xmlFinal xml, @valoarePunctIncasare decimal(12,5), @valoarePunctVanzare decimal(12,5), @durataInput int, @clipboardIsSimilar bit 
	
	select	@UID_Card = @parXML.value('(/row/@uidCardFidelizare)[1]', 'varchar(50)'),
			@durataInput=ISNULL(@parXML.value('(/row/@durataInput)[1]', 'int'), 0) , /* timpul(in ms) de la tastarea primei litere pana la apasare <enter>  */
			@clipboardIsSimilar=ISNULL(@parXML.value('(/row/@clipboardIsSimilar)[1]', 'bit'), 0) /* flag trimis 'true' daca textul din clipboard e similar cu textul cautat */

	set @puncte = isnull(floor((select sum((case when p.tip='C' then -1 else 1 end) * puncte)
							from PvPuncte p where p.uid_card=@UID_Card)),0)
	
	exec luare_date_par @tip='PV', @par='VALPUNCTI', @val_l=0, @val_n=@valoarePunctIncasare output, @val_a=''
	exec luare_date_par @tip='PV', @par='VALPUNCTV', @val_l=0, @val_n=@valoarePunctVanzare output, @val_a=''

	set @xmlFinal=
		( select c.UID uidCardFidelizare, c.Nume_posesor_card numeTitularCard, 
					c.Tert as tert, c.Punct_livrare idLocatie, c.Id_Persoana_contact idDelegat,
					c.Mijloc_de_transport idMasina,
					@puncte as puncte, @valoarePunctIncasare as valoarePunctIncasare, @valoarePunctVanzare as valoarePunctVanzare
			from CarduriFidelizare c 
			where isnull(c.blocat,0)<>1
			and c.UID=@UID_Card
			for xml raw)
	
	--insert CarduriFidelizare(UID, Nume_posesor_card) select '123456789012345678901', 'User test'	

	if exists (select 1 from sysobjects where type='P' and name='wIaPuncteCardFidelizareSP1')
	begin
		-- procedura poate face alte modificari asupra xmlFinal.
		exec wIaPuncteCardFidelizareSP1 @sesiune=@sesiune, @parXML=@parXML, @xmlFinal=@xmlFinal output
		
		if @xmlFinal is null
			return 0
	end

	select @xmlFinal for xml path(''), root ('Mesaje')

end try
begin catch
	declare @msgEroare varchar(500)
	set @msgEroare = ERROR_MESSAGE()+'(wIaPuncteCardFidelizare)'
	raiserror(@msgeroare,11,1)
end catch
