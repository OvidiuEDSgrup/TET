--***
create procedure wScriuConfigMachete_Filtre (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @t_meniu varchar(20), @t_tip varchar(20), @t_ordine int, @t_vizibil bit, @t_descriere varchar(50),
		@t_prompt1 varchar(20), @t_datafield1 varchar(100), @t_interval bit, @t_prompt2 varchar(20), @t_datafield2 varchar(100),
		@tip_m varchar(20),
		@o_meniu varchar(20), @o_tip varchar(20), @o_datafield1 varchar(50), @update bit, @o_ordine int

begin try
	set @t_meniu = @parXML.value('(/row/@t_meniu)[1]','varchar(20)')
	set @t_tip = @parXML.value('(/row/@t_tip)[1]','varchar(20)')
	set @t_ordine = isnull(@parXML.value('(/row/@t_ordine)[1]','int'),0)
	set @t_vizibil = isnull(@parXML.value('(/row/@t_vizibil)[1]','bit'),0)
	set @t_descriere = @parXML.value('(/row/@t_descriere)[1]','varchar(50)')
	set @t_prompt1 = @parXML.value('(/row/@t_prompt1)[1]','varchar(20)')
	set @t_datafield1 = @parXML.value('(/row/@t_datafield1)[1]','varchar(100)')
	set @t_interval = isnull(@parXML.value('(/row/@t_interval)[1]','bit'),0)
	set @t_prompt2 = @parXML.value('(/row/@t_prompt2)[1]','varchar(20)')
	set @t_datafield2 = @parXML.value('(/row/@t_datafield2)[1]','varchar(100)')

	set @tip_m = @parXML.value('(/row/@tip_m)[1]','varchar(20)')
	set @o_meniu = isnull(@parXML.value('(/row/@o_t_meniu)[1]','varchar(20)'),'')
	set @o_tip = @parXML.value('(/row/@o_t_tip)[1]','varchar(20)')
	set @o_datafield1 = @parXML.value('(/row/@o_t_datafield1)[1]','varchar(50)')
	set @o_ordine = @parXML.value('(/row/@o_t_ordine)[1]','int')

	set @update = (case when @o_meniu='' then 0 else 1 end)--isnull(@parXML.value('(/row/@update)[1]','bit'),0)

	if isnull(@t_meniu,'')=''
	begin
		set @mesaj = 'Meniul nu este completat.'
		raiserror(@mesaj,16,1)
	end

	if isnull(@t_tip,'')='' and isnull(@tip_m,'')<>''
	begin
		set @mesaj = 'Tipul nu este completat.'
		raiserror(@mesaj,16,1)
	end

	if (@t_ordine < 1)
	begin
		set @mesaj = 'Numarul de ordine trebuie sa fie mai mare decat 0.'
		raiserror(@mesaj,16,1)
	end

	-- Se verifica sa nu existe deja acest filtru
	if exists(select 1 from webConfigFiltre wf
					where wf.Meniu = @t_meniu
					and (wf.Tip=@t_tip)
					and (isnull(wf.DataField1,'')=isnull(@t_datafield1,''))
			) and (@update=0)
	begin
		set @mesaj = 'Acest filtru deja exista in webConfigFiltre.'
		raiserror(@mesaj,16,1)
	end
	
		/* Se renumeroteaza toate campurile*/
	select meniu, tip, datafield1,row_number() over (order by ordine,descriere)+(case when row_number() over (order by ordine,descriere)<@t_ordine or @update=1 then 0 else 1 end) ordine
		into #ptOrdine
		from webconfigfiltre
			where Meniu=@t_meniu
			and isnull(Tip,'')=isnull(@t_tip,'')

	update v 
		set ordine=n.ordine+
			(case when @o_ordine is null then 0
				when v.ordine>@o_ordine and v.ordine<=@t_ordine then -1
				when v.ordine>=@t_ordine and v.ordine<@o_ordine then 1
				else 0 
			 end)
	from webConfigfiltre v
	inner join #ptOrdine n on v.meniu=n.meniu and isnull(v.tip,'')=isnull(n.tip,'') /*and isnull(v.Subtip,'')=isnull(n.Subtip,'')*/ and v.DataField1=n.DataField1

	if @update=0
	begin
		insert into webConfigFiltre(Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2, detalii)
		values(@t_meniu, @t_tip, @t_ordine, @t_vizibil, null, @t_descriere, @t_prompt1, @t_datafield1, @t_interval, @t_prompt2, @t_datafield2, null)
	end
	else
	begin
		update webConfigFiltre
		set Meniu=@t_meniu, Tip=@t_tip, Ordine=@t_ordine, Vizibil=@t_vizibil, Descriere=@t_descriere, Prompt1=@t_prompt1, DataField1=@t_datafield1, 
		Interval=@t_interval, Prompt2=@t_prompt2, DataField2=@t_datafield2
		where Meniu=@o_meniu
			and isnull(Tip,'')=isnull(@o_tip,'') 
			and isnull(DataField1,'')=isnull(@o_datafield1,'')
	end

	exec wIaConfigMachete_Filtre @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	set @mesaj = error_message() + ' (wScriuConfigMachete_Filtre)'
	raiserror(@mesaj, 11, 1)
end catch
