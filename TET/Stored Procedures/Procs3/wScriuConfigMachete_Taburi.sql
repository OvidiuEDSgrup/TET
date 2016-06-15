--***
create procedure wScriuConfigMachete_Taburi (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @b_meniu_sursa varchar(50), @b_tip_sursa varchar(50), @b_nume_tab varchar(100), @b_icoana varchar(500), @b_tip_macheta varchar(20),
		@b_cod_meniu varchar(20), @b_tip_doc varchar(20), @b_proc_populare varchar(100), @b_ordine int, @b_vizibil bit,
		@o_meniu_sursa varchar(50), @o_tip_sursa varchar(50), @o_nume_tab varchar(100), @update bit

begin try
	set @b_meniu_sursa = @parXML.value('(/row/@b_meniu_sursa)[1]','varchar(50)')
	set @b_tip_sursa = @parXML.value('(/row/@b_tip_sursa)[1]','varchar(50)')
	set @b_nume_tab = @parXML.value('(/row/@b_nume_tab)[1]','varchar(100)')
	set @b_icoana = @parXML.value('(/row/@b_icoana)[1]','varchar(500)')
	set @b_tip_macheta = @parXML.value('(/row/@b_tip_macheta)[1]','varchar(20)')
	set @b_cod_meniu = @parXML.value('(/row/@b_cod_meniu)[1]','varchar(20)')
	set @b_tip_doc = @parXML.value('(/row/@b_tip_doc)[1]','varchar(20)')
	set @b_proc_populare = @parXML.value('(/row/@b_proc_populare)[1]','varchar(100)')
	set @b_ordine = isnull(@parXML.value('(/row/@b_ordine)[1]','int'),0)
	set @b_vizibil = isnull(@parXML.value('(/row/@b_vizibil)[1]','bit'),0)

	set @o_meniu_sursa = isnull(@parXML.value('(/row/@o_b_meniu_sursa)[1]','varchar(50)'),'')
	set @o_tip_sursa = @parXML.value('(/row/@o_b_tip_sursa)[1]','varchar(50)')
	set @o_nume_tab = @parXML.value('(/row/@o_b_nume_tab)[1]','varchar(100)')

	set @update = (case when @o_meniu_sursa='' then 0 else 1 end) --isnull(@parXML.value('(/row/@update)[1]','bit'),0)

	set @b_tip_sursa=isnull(@b_tip_sursa,'')
	if isnull(@b_meniu_sursa,'')=''
	begin
		set @mesaj = 'Meniul sursa nu este completat.'
		raiserror(@mesaj,16,1)
	end
/*
	if isnull(@b_tip_sursa,'')=''
	begin
		set @mesaj = 'Tipul sursa nu este completat.'
		raiserror(@mesaj,16,1)
	end
*/
	if isnull(@b_nume_tab,'')=''
	begin
		set @mesaj = 'Numele tabului nu este completat.'
		raiserror(@mesaj,16,1)
	end

	if (@b_ordine < 1)
	begin
		set @mesaj = 'Numarul de ordine trebuie sa fie mai mare decat 0.'
		raiserror(@mesaj,16,1)
	end

	-- Se verifica sa nu existe deja acest filtru
	if exists(select 1 from webConfigTaburi wt
					where wt.MeniuSursa = @b_meniu_sursa
					and (wt.TipSursa=@b_tip_sursa)
					and (wt.NumeTab=@b_nume_tab)
			) and (@update=0)
	begin
		set @mesaj = 'Acest tab deja exista in webConfigTaburi.'
		raiserror(@mesaj,16,1)
	end

	if @update=0
	begin
		insert into webConfigTaburi(MeniuSursa, TipSursa, NumeTab, Icoana, TipMachetaNoua, MeniuNou, TipNou, ProcPopulare, Ordine, Vizibil, --publicabil, 
																																							detalii)
		values(@b_meniu_sursa, @b_tip_sursa, @b_nume_tab, @b_icoana, @b_tip_macheta, @b_cod_meniu, @b_tip_doc, @b_proc_populare, @b_ordine, @b_vizibil,-- 1, 
																																							null )
	end
	else
	begin
		update webConfigTaburi
		set MeniuSursa=@b_meniu_sursa, TipSursa=@b_tip_sursa, NumeTab=@b_nume_tab, Icoana=@b_icoana, TipMachetaNoua=@b_tip_macheta, MeniuNou=@b_cod_meniu,
			TipNou=@b_tip_doc, ProcPopulare=@b_proc_populare, Ordine=@b_ordine, Vizibil=@b_vizibil
		where MeniuSursa=@o_meniu_sursa
			and (TipSursa=@o_tip_sursa)
			and (NumeTab=@o_nume_tab)
	end

	exec wIaConfigMachete_Taburi @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	set @mesaj = error_message() + ' (wScriuConfigMachete_Taburi)'
	raiserror(@mesaj, 11, 1)
end catch
