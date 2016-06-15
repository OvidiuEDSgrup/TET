--***
create procedure wScriuConfigMachete_Tipuri (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @p_meniu varchar(20), @p_tip varchar(20), @p_subtip varchar(20), @p_ordine int, @p_nume varchar(50), @p_descriere varchar(500),
		@p_textadaugare varchar(60), @p_textmodificare varchar(60), @p_procdate varchar(60), @p_procscriere varchar(60), @p_procstergere varchar(60),
		@p_procdatepoz varchar(60), @p_procscrierepoz varchar(60), @p_procstergerepoz varchar(60), @p_vizibil bit, @p_fel varchar(1), @p_procPopulare varchar(60),
		@p_tasta varchar(20), @p_procinchideremacheta varchar(60),
		@o_meniu varchar(20), @o_tip varchar(20), @o_subtip varchar(20), @o_ordine int, @update bit

begin try
	set @p_meniu = @parXML.value('(/row/@p_meniu)[1]','varchar(20)')
	set @p_tip = @parXML.value('(/row/@p_tip)[1]','varchar(20)')
	set @p_subtip = @parXML.value('(/row/@p_subtip)[1]','varchar(20)')
	set @p_ordine = isnull(@parXML.value('(/row/@p_ordine)[1]','int'),0)
	set @p_nume = @parXML.value('(/row/@p_nume)[1]','varchar(50)')
	set @p_descriere = @parXML.value('(/row/@p_descriere)[1]','varchar(500)')
	set @p_textadaugare = @parXML.value('(/row/@p_textadaugare)[1]','varchar(60)')
	set @p_textmodificare = @parXML.value('(/row/@p_textmodificare)[1]','varchar(60)')
	set @p_procdate = @parXML.value('(/row/@p_procdate)[1]','varchar(60)')
	set @p_procscriere = @parXML.value('(/row/@p_procscriere)[1]','varchar(60)')
	set @p_procstergere = @parXML.value('(/row/@p_procstergere)[1]','varchar(60)')
	set @p_procdatepoz = @parXML.value('(/row/@p_procdatepoz)[1]','varchar(60)')
	set @p_procscrierepoz = @parXML.value('(/row/@p_procscrierepoz)[1]','varchar(60)')
	set @p_procstergerepoz = @parXML.value('(/row/@p_procstergerepoz)[1]','varchar(60)')
	set @p_vizibil = isnull(@parXML.value('(/row/@p_vizibil)[1]','bit'),0)
	set @p_fel = @parXML.value('(/row/@p_fel)[1]','varchar(1)')
	set @p_procPopulare = @parXML.value('(/row/@p_procpopulare)[1]','varchar(60)')
	set @p_tasta = @parXML.value('(/row/@p_tasta)[1]','varchar(20)')
	set @p_procinchideremacheta = @parXML.value('(/row/@p_procinchideremacheta)[1]','varchar(60)')

	set @o_meniu = @parXML.value('(/row/@o_p_meniu)[1]','varchar(20)')
	set @o_tip = @parXML.value('(/row/@o_p_tip)[1]','varchar(20)')
	set @o_subtip = @parXML.value('(/row/@o_p_subtip)[1]','varchar(20)')
	set @o_ordine = @parXML.value('(/row/@o_p_ordine)[1]','int')

	set @update = case when @o_meniu is null then 0 else 1 end

	if isnull(@p_meniu,'')=''
	begin
		set @mesaj = 'Meniul nu este completat.'
		raiserror(@mesaj,16,1)
	end

	if (@p_ordine < 1)
	begin
		set @mesaj = 'Numarul de ordine trebuie sa fie mai mare decat 0.'
		raiserror(@mesaj,16,1)
	end
	
	if (@p_fel in ('M','A') and isnull(@p_subtip,'')<>'')
		raiserror('Nu e permisa completarea campului fel cu "Doar odificare" sau "Doar adaugare" pentru subtipuri!',16,1)

	-- Se verifica sa nu existe deja acest tip
	if exists(select 1 from webConfigTipuri wp
					where wp.Meniu = @p_meniu
					and (isnull(wp.Tip,'')=isnull(@p_tip,''))
					and (isnull(wp.Subtip,'')=isnull(@p_subtip,''))
					and (isnull(wp.Ordine,0)=isnull(@p_ordine,0))
			) and (@update=0)
	begin
		set @mesaj = 'Acest tip deja exista in webConfigTipuri.'
		raiserror(@mesaj,16,1)
	end

	if @update=0
	begin
		insert into webConfigTipuri(Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, 
										ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare, tasta, --publicabil,
												ProcInchidereMacheta, detalii)
		values(@p_meniu, @p_tip, @p_subtip, @p_ordine, @p_nume, @p_descriere, @p_textadaugare, @p_textmodificare, @p_procdate, @p_procscriere, @p_procstergere,
				@p_procdatepoz, @p_procscrierepoz, @p_procstergerepoz, @p_vizibil, @p_fel, @p_procPopulare, @p_tasta, --1,
							@p_procinchideremacheta, null )
	end
	else
	begin
		update webConfigTipuri
		set Meniu=@p_meniu, Tip=@p_tip, Subtip=@p_subtip, Ordine=@p_ordine, Nume=@p_nume, Descriere=@p_descriere, TextAdaugare=@p_textadaugare,
			TextModificare=@p_textmodificare, ProcDate=@p_procdate, ProcScriere=@p_procscriere, ProcStergere=@p_procstergere, ProcDatePoz=@p_procdatepoz,
			ProcScrierePoz=@p_procscrierepoz, ProcStergerePoz=@p_procstergerepoz, Vizibil=@p_vizibil, Fel=@p_fel, procPopulare=@p_procpopulare, Tasta=@p_tasta,
			ProcInchidereMacheta=@p_procinchideremacheta
		where Meniu=@o_meniu
			and isnull(Tip,'')=isnull(@o_tip,'') 
			and isnull(Subtip,'')=isnull(@o_subtip,'')
			and isnull(Ordine,'')=isnull(@o_ordine,'')
	end

	exec wIaConfigMachete_Tipuri @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	set @mesaj = error_message() + ' (wScriuConfigMachete_Tipuri)'
	raiserror(@mesaj, 11, 1)
end catch
