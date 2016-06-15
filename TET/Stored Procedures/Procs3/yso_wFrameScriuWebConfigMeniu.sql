--***
CREATE procedure [dbo].[yso_wFrameScriuWebConfigMeniu] (@sesiune varchar(50), @parXML XML)
as

declare @eroare varchar(1000)
begin try
declare	--@Proprietar int ,@IdUtilizator int , 
		@id int, @NumeMeniu varchar(30), @idParinte int, @Icoana varchar(50),
		@TipMacheta varchar(2),@Meniu varchar(2),
		
		@Tip varchar(10), @Subtip varchar(10), @Nume varchar(100), @Descriere varchar(500),
		@TextAdaugare varchar(100), @TextModificare  varchar(100), @ProcDate  varchar(100), @ProcDatePoz  varchar(100),
		@ProcScriere  varchar(100), @ProcScrierePoz varchar(100), @ProcStergere varchar(100), @ProcStergerePoz varchar(100),
		@Vizibil int, @Fel varchar(10), @procPopulare varchar(100),
		@Modul varchar(5), 
		@_tipmod int, @_inferioare int,
		@o_id int, @o_idParinte int, @o_TipMacheta varchar(2),@o_Meniu varchar(2), @o_Modul varchar(5),
		@update int, @_din_alta_procedura int
		--@Ordine int 
		--Proprietar, id, Nume, idParinte, Icoana, TipMacheta, Meniu, Modul, --data_operarii
	
select	--@Proprietar=@parXML.value('(/row/@Proprietar)[1]','int'),
		--@IdUtilizator=@parXML.value('(/row/@IdUtilizator)[1]','int'),
	@id=@parXML.value('(/row/@Id)[1]','int'),
	@NumeMeniu=@parXML.value('(/row/@NumeMeniu)[1]','varchar(30)'),
	@idParinte=@parXML.value('(/row/@idParinte)[1]','int'),
	@Icoana=@parXML.value('(/row/@Icoana)[1]','varchar(50)'),
	@TipMacheta=@parXML.value('(/row/@TipMacheta)[1]','varchar(2)'),
	@Meniu=@parXML.value('(/row/@Meniu)[1]','varchar(2)'),
	@Modul=@parXML.value('(/row/@Modul)[1]','varchar(5)'),
	@Tip=@parXML.value('(/row/@Tip)[1]','varchar(10)'),
	@Subtip=@parXML.value('(/row/@Subtip)[1]','varchar(10)'),
	@Nume=@parXML.value('(/row/@Nume)[1]','varchar(100)'),
	@Descriere=@parXML.value('(/row/@Descriere)[1]','varchar(500)'),
	@TextAdaugare=@parXML.value('(/row/@TextAdaugare)[1]','varchar(100)'),
	@TextModificare=@parXML.value('(/row/@TextModificare)[1]','varchar(100)'),
	@ProcDate=@parXML.value('(/row/@ProcDate)[1]','varchar(100)'),
	@ProcDatePoz=@parXML.value('(/row/@ProcDatePoz)[1]','varchar(100)'),
	@ProcScriere=@parXML.value('(/row/@ProcScriere)[1]','varchar(100)'),
	@ProcScrierePoz=@parXML.value('(/row/@ProcScrierePoz)[1]','varchar(100)'),
	@ProcStergere=@parXML.value('(/row/@ProcStergere)[1]','varchar(100)'),
	@ProcStergerePoz=@parXML.value('(/row/@ProcStergerePoz)[1]','varchar(100)'),
	@Vizibil=@parXML.value('(/row/@Vizibil)[1]','int'),
	@Fel=@parXML.value('(/row/@Fel)[1]','varchar(10)'),
	@procPopulare=@parXML.value('(/row/@procPopulare)[1]','varchar(100)'),
	
	@_tipmod=@parXML.value('(/row/@_tipmod)[1]','int'),			-->	1=Modificare;	2=Copiere;	3=Mutare;
	@_inferioare=@parXML.value('(/row/@_inferioare)[1]','int'),	--> daca se vor copia si liniile inferioare de configurare - doar pentru copiere
	
	@update=isnull(@parXML.value('(/row/@update)[1]','int'),0),
	@_din_alta_procedura=(case when isnull(@parXML.value('(/row/@_din_alta_procedura)[1]','int'),'')='' then 0 else 1 end),
	@o_TipMacheta=@parXML.value('(/row/@o_TipMacheta)[1]','varchar(2)'),
	@o_Meniu=@parXML.value('(/row/@o_Meniu)[1]','varchar(2)')
	/*
	,@o_Modul=@parXML.value('(/row/@o_Modul)[1]','varchar(5)')
	,@o_id=@parXML.value('(/row/@o_id)[1]','int')
	,@o_idParinte=@parXML.value('(/row/@o_idParinte)[1]','int')*/

	select @o_id=id, @o_idParinte=w.idParinte, @o_Modul=isnull(w.Modul,'')
		from webConfigMeniu w where w.TipMacheta=@o_TipMacheta and w.Meniu=@o_Meniu
	/**	sectiune erori de operare generale
		Textele - in afara de nume obiecte - si procedurile - in afara de aducere date pt tipuri - nu sunt obligatorii;
		Id, idParinte, Ordine pot sa nu fie completate, se vor genera pe baza datelor deja existente
				(ID, idParinte = urmator+1000, iar ordine>1000)
	*/
	if (isnull(@TipMacheta,'')='')	raiserror('Completati tipul machetei!',16,1)
	if (isnull(@Meniu,'')='')	raiserror('Completati codul meniului!',16,1)
	if (isnull(@NumeMeniu,'')='')	raiserror('Completati numele meniului!',16,1)
	if (isnull(@idParinte,0)=0 and isnull(@Tip,'')<>'')	raiserror('Completati identificatorul meniului parinte!',16,1)
	if (isnull(@Subtip,'')<>'') and isnull(@Tip,'')='' raiserror('Completati tipul machetei!',16,1)
	--if (isnull(@Tip,'')<>'') raiserror('Completati numele machetei!',16,1)
	if (isnull(@Tip,'')<>'' and isnull(@Subtip,'')='' and isnull(@ProcDate,'')='') raiserror('Completati procedura "procDate"!',16,1)
if (@update=0)
--I.
	begin
		--> meniuri
		set @id=isnull((select max(id) from webConfigMeniu),0)+1
		if @idParinte is not null and not exists (select 1 from webConfigMeniu w where w.Id=@idParinte)
			insert into webConfigMeniu(--Proprietar, 
			id, Nume, idParinte, Icoana, TipMacheta, Meniu, Modul)
			select --@Proprietar, 
			@idParinte, '<R>'+@NumeMeniu, null, null, '', null, ''
		else
		
		insert into webConfigMeniu(--Proprietar, 
		id, Nume, idParinte, Icoana, TipMacheta, Meniu, Modul)
		select --@Proprietar, 
		@id, @NumeMeniu, @idParinte, @Icoana, @TipMacheta, @Meniu, @Modul
		/* in lucru
		--> tipuri
		if @Tip is not null and 
			not exists (select 1 from webconfigtipuri w where w.Meniu=@Meniu and w.TipMacheta=@TipMacheta and w.tip=@Tip)
			insert into webConfigTipuri(IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare,
							ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare)
			----------> select null IdUtilizator, @TipMacheta TipMacheta, @Meniu Meniu, @Tip Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, 
					ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare*/
		
	end
if (@update=1)
	if (@id<>@o_id or @idParinte<>@o_idParinte or @TipMacheta<>@o_TipMacheta or @Meniu<>@o_Meniu or @Modul<>@o_Modul)
		raiserror('Nu este permisa modificarea nici unuia din campurile id, idParinte, TipMacheta, Meniu sau Modul!',16,1)
	else
	begin
		select * from webconfigmeniu where id=@o_id and idParinte=@o_idParinte and
				TipMacheta=@o_TipMacheta and Meniu=@o_Meniu and Modul=@o_Modul
		update webConfigMeniu
			set Nume=@NumeMeniu, Icoana=@Icoana
			where id=@o_id and idParinte=@o_idParinte and TipMacheta=@o_TipMacheta and Meniu=@o_Meniu and Modul=@o_Modul
	end
	
if (@_din_alta_procedura=0)	/**	daca nu este apelat din alta procedura trebuie refresh: */
	exec wFrameIauWebConfigMeniuri @sesiune, @parXML
--else
--	*/
--	for xml raw
end try
begin catch
	set @eroare='wFrameScriuWebConfigMeniu (linia '+convert(varchar(20),ERROR_LINE())+'):'+char(10)+
				ERROR_MESSAGE()
	raiserror(@eroare,16,1)
end catch