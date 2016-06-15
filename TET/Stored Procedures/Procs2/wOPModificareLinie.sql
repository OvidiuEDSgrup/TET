
create procedure wOPModificareLinie @sesiune varchar(50), @parXML xml
as

declare @mesaj varchar(500), @meniu varchar(20), @nume varchar(50), @sursa varchar(50), @nrordine decimal(7,2), @vizibil bit, @o_nrordine decimal(7,2),
		@tip varchar(20), @subtip varchar(20)

begin try
	select
		@meniu = @parXML.value('(/row/@meniu)[1]','varchar(20)'),
		@nume = isnull(@parXML.value('(/row/@nume)[1]','varchar(50)'),''),
		@sursa = isnull(@parXML.value('(/row/@sursa)[1]','varchar(50)'),''),
		@nrordine = isnull(@parXML.value('(/row/@mo_nrordine)[1]','decimal(7,2)'),0),
		@vizibil = isnull(@parXML.value('(/row/@mo_vizibil)[1]','bit'),0),
		@o_nrordine = isnull(@parXML.value('(/row/@o_mo_nrordine)[1]','decimal(7,2)'),0),
		@tip = isnull(@parXML.value('(/row/@tip_m)[1]','varchar(20)'),''),
		@subtip = isnull(@parXML.value('(/row/@subtip_m)[1]','varchar(20)'),'')
		--@sursa = isnull(@parXML.value('(/row/@sursa)[1]','varchar(50)'),'')

	if @sursa not in ('webConfigMeniu', 'webConfigTipuri')
	begin
		set @mesaj = 'Linia selectata nu este modificabila din aceasta macheta. (Sursa: ' + @sursa + ')'
		raiserror(@mesaj,16,1)
	end

	if isnull(@meniu,'')=''
	begin
		set @mesaj = 'Acest meniu nu poate fi modificat.'
		raiserror(@mesaj,16,1)
	end	
	
	if (@nrordine = 0)
	begin
		set @mesaj = 'Numarul de ordine trebuie sa fie mai mare decat 1.'
		raiserror(@mesaj,16,1)
	end

	select @mesaj=''
	if @sursa='webConfigMeniu'
	begin
		select @mesaj='Exista deja meniul '+ meniu + ' (' + nume + ') cu numarul de ordine ' + convert(varchar(20),@nrordine) + '.'
			from webConfigMeniu where Meniu=@meniu and NrOrdine=@nrordine and @nrordine<>@o_nrordine
		if len(isnull(@mesaj,''))>0
			raiserror(@mesaj,16,1)
		else
			update webConfigMeniu set NrOrdine=@nrordine, vizibil=@vizibil where Meniu=@meniu
	end
	else
	begin
		select @mesaj='Exista deja o linie in webConfigTipuri cu meniul '+t.meniu+
			(case when isnull(t.tip,'')='' then '' else ', tipul '+t.tip end)+
			(case when isnull(t.subtip,'')='' then '' else ', subtipul '+t.subtip end)+' ('+t.Nume+') cu numarul de ordine '++ convert(varchar(20),@nrordine) + '.'
			from webConfigTipuri t where Meniu=@meniu and isnull(tip,'')=@tip and isnull(subtip,'')=@subtip and Ordine=@nrordine and @nrordine<>@o_nrordine
		if len(isnull(@mesaj,''))>0
			raiserror(@mesaj,16,1)
		else
		begin
		--select 'test update', @meniu, @tip and isnull(subtip,'')=subtip
			update webConfigTipuri set Ordine=@nrordine, vizibil=@vizibil where Meniu=@meniu and isnull(tip,'')=@tip and isnull(subtip,'')=@subtip
		end
	end
	declare @x xml
	select @x=(select @meniu meniu, @nume nume, @nrordine nrordine, @vizibil vizibil, @tip tip_m, @subtip subtip_m, @sursa sursa for xml raw)
	exec wOPModificareLinie_p @sesiune=@sesiune, @parXML=@x
end try	

begin catch
	set @mesaj = error_message() + ' (wOPModificareLinie)'
	raiserror(@mesaj, 11, 1)
end catch
