
create procedure wOPAdaugaMeniuConfig @sesiune varchar(50), @parXML xml
as

declare @mesaj varchar(500), @meniu varchar(20), @nume varchar(30), @parinte varchar(20), @tipmacheta varchar(10), 
		@ordine decimal(7,2), @icoana varchar(100), @vizibil bit,
		@sursa varchar(200),
		@o_meniu varchar(200), @update varchar(200),
		@parx xml
select @mesaj=''
begin try

	if object_id('tempdb..#tipuri') is not null drop table #tipuri

	select	@meniu = @parXML.value('(/row/@meniu)[1]','varchar(20)')
			,@nume = @parXML.value('(/row/@nume)[1]','varchar(30)')
			,@tipmacheta = @parXML.value('(/row/@tip_macheta)[1]','varchar(10)')
			,@parinte = @parXML.value('(/row/@parinte)[1]','varchar(20)')	--?
			,@icoana = @parXML.value('(/row/@icoana)[1]','varchar(100)')	--?
			,@vizibil = isnull(@parXML.value('(/row/@vizibil)[1]','bit'),0)
			,@ordine = @parXML.value('(/row/@nrordine)[1]','decimal(7,2)')
			
			,@sursa = @parXML.value('(/row/@sursa)[1]','varchar(200)')
			
			,@o_meniu = @parXML.value('(/row/@o_meniu)[1]','varchar(200)')
	
	select @update= (case when @o_meniu is null or not exists (select 1 from webconfigmeniu w where w.meniu=@o_meniu) then 0 else 1 end)

	if @update=1 and @meniu<>@o_meniu	
	begin	--> mai incolo poate se va inlocui cu ceva actualizare cascadata a configurarilor
		create table #tipuri(meniu varchar(20))
		select @parx=(select @o_meniu meniu for xml raw('parametri'))
		exec wOPGasesteRelatiiConfigurari_tabela @sesiune=@sesiune, @parXML=null
		exec wOPGasesteRelatiiConfigurari @sesiune=@sesiune, @parXML=@parx
		if (select count(1) from #tipuri)>0
			raiserror ('Nu se poate inlocui codul unui meniu care are configurari!',16,1)
	end
	if isnull(@meniu,'') = ''
	begin
		set @mesaj = 'Codul meniului este necompletat.'
		raiserror(@mesaj,16,1)
	end

	if isnull(@nume,'') = ''
	begin
		set @mesaj = 'Numele meniului este necompletat.'
		raiserror(@mesaj,16,1)
	end

	if isnull(@ordine,0) < 1
	begin
		set @mesaj = 'Numarul de ordine nu poate fi mai mic decat 1.'
		raiserror(@mesaj,16,1)
	end

	if @update=0
	begin
		if exists(select 1 from webConfigMeniu where Meniu=@meniu)
		begin
			set @mesaj = 'Exista deja un meniu cu acest cod (' + @meniu + ').'
			raiserror(@mesaj,16,1)
		end

		insert into webConfigMeniu(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)--,publicabil)
		values (@meniu, @nume, @parinte, @icoana, @tipmacheta, @ordine,'','',null,@vizibil)--,1)
	end
	
	if @update=1
	begin
		--select @o_meniu
		--* from webconfigmeniu w where w.meniu=@o_meniu
		if @sursa='webConfigMeniu'
			update w set Meniu=@meniu, Nume=@nume, MeniuParinte=@parinte, Icoana=isnull(@icoana,w.icoana),
				TipMacheta=@tipmacheta, NrOrdine=@ordine, Componenta='', Semnatura='', Detalii=null, vizibil=@vizibil
			from webconfigmeniu w
			where w.meniu=@o_meniu
		else
			set @mesaj='Modificarea datelor meniului este permisa doar de pe randul aferent meniului!'
	end
	
	declare @x xml
	select @x=(select @meniu as meniu for xml raw)
	exec wOPAdaugaMeniuConfig_p @sesiune=@sesiune, @parxml=@x
	if len(@mesaj)>0
		raiserror(@mesaj,16,1)
end try

begin catch
	set @mesaj = error_message() + ' (wOPAdaugaMeniuConfig)'
end catch
if object_id('tempdb..#tipuri') is not null drop table #tipuri
if len(@mesaj)>0 raiserror(@mesaj, 11, 1)
