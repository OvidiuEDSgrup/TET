--***
create procedure wScriuConfigMachete_Form (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @r_meniu varchar(20), @r_tip varchar(2), @r_subtip varchar(2), @r_ordine int, @r_nume varchar(50), @r_tip_obiect varchar(50),
		@r_datafield varchar(50), @r_labelfield varchar(50), @r_latime int, @r_vizibil bit, @r_modificabil bit, @r_procsql varchar(50), @r_listavalori varchar(100),
		@r_listaetichete varchar(600), @r_initializare varchar(50), @r_prompt varchar(50), @r_formula varchar(max), 
		@o_meniu varchar(20), @o_tip varchar(2), @o_subtip varchar(2), @o_datafield varchar(50), @update bit,@o_ordine int,
		@detalii xml
		
begin try
	set @r_meniu = @parXML.value('(/row/@r_meniu)[1]','varchar(20)')
	set @r_tip = @parXML.value('(/row/@r_tip)[1]','varchar(2)')
	set @r_subtip = @parXML.value('(/row/@r_subtip)[1]','varchar(2)')
	set @r_ordine = isnull(@parXML.value('(/row/@r_ordine)[1]','int'),0)
	set @r_nume = @parXML.value('(/row/@r_nume)[1]','varchar(50)')
	set @r_tip_obiect = @parXML.value('(/row/@r_tip_obiect)[1]','varchar(50)')
	set @r_datafield = @parXML.value('(/row/@r_datafield)[1]','varchar(50)')
	set @r_labelfield = @parXML.value('(/row/@r_labelfield)[1]','varchar(50)')
	set @r_latime = @parXML.value('(/row/@r_latime)[1]','int')
	set @r_vizibil = isnull(@parXML.value('(/row/@r_vizibil)[1]','bit'),0)
	set @r_modificabil = isnull(@parXML.value('(/row/@r_modificabil)[1]','bit'),0)
	set @r_procsql = @parXML.value('(/row/@r_procsql)[1]','varchar(50)')
	set @r_listavalori = @parXML.value('(/row/@r_listavalori)[1]','varchar(100)')
	set @r_listaetichete = @parXML.value('(/row/@r_listaetichete)[1]','varchar(600)')
	set @r_initializare = @parXML.value('(/row/@r_initializare)[1]','varchar(50)')
	set @r_prompt = @parXML.value('(/row/@r_prompt)[1]','varchar(50)')
	set @detalii = @parXML.query('(row/detalii/row)[1]')
	set @r_formula = @parXML.value('(/row/@r_formula)[1]','varchar(max)')

	set @o_meniu = @parXML.value('(/row/@o_r_meniu)[1]','varchar(20)')
	set @o_tip = @parXML.value('(/row/@o_r_tip)[1]','varchar(2)')
	set @o_subtip = @parXML.value('(/row/@o_r_subtip)[1]','varchar(2)')
	set @o_datafield = @parXML.value('(/row/@o_r_datafield)[1]','varchar(50)')
	set @o_ordine = @parXML.value('(/row/@o_r_ordine)[1]','int')
	
	set @update = case when @o_meniu is null then 0 else 1 end

	if isnull(@r_meniu,'')=''
	begin
		set @mesaj = 'Meniul nu este completat.'
		raiserror(@mesaj,16,1)
	end

	if (@r_ordine < 0)
	begin
		set @mesaj = 'Numarul de ordine trebuie sa fie mai mare decat 0.'
		raiserror(@mesaj,16,1)
	end

	-- Se verifica sa nu existe deja acest form
	if exists(select 1 from webConfigForm wf 
					where wf.Meniu = @r_meniu
					and (isnull(wf.Tip,'')=isnull(@r_tip,''))
					and (isnull(wf.Subtip,'')=isnull(@r_subtip,''))
					and (isnull(wf.DataField,'')=isnull(@r_datafield,''))
			) and (@update=0)
	begin
		set @mesaj = 'Acest form deja exista in webConfigForm.'
		raiserror(@mesaj,16,1)
	end

	/* Se renumeroteaza toate campurile*/
	select meniu, tip, subtip, datafield,row_number() over (order by ordine,nume)+(case when row_number() over (order by ordine,nume)<@r_ordine or @update=1 then 0 else 1 end) ordine
		into #ptOrdine
		from webconfigform 
			where Meniu=@r_meniu
			and isnull(Tip,'')=isnull(@r_tip,'') 
			and isnull(Subtip,'')=isnull(@r_subtip,'')

	update v 
		set ordine=n.ordine+
			(case when @o_ordine is null then 0
				when v.ordine>@o_ordine and v.ordine<=@r_ordine then -1
				when v.ordine>=@r_ordine and v.ordine<@o_ordine then 1
				else 0 
			 end)
	from webConfigForm v
	inner join #ptOrdine n on v.meniu=n.meniu and isnull(v.tip,'')=isnull(n.tip,'') and isnull(v.Subtip,'')=isnull(n.Subtip,'') and v.DataField=n.DataField


	if @r_ordine=0
		set @r_ordine=1

	if @update=0
	begin
		insert into webConfigForm(Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, 
								ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula, detalii)
		values(@r_meniu, @r_tip, @r_subtip, @r_ordine, @r_nume, @r_tip_obiect, @r_datafield, @r_labelfield, @r_latime, @r_vizibil, @r_modificabil, @r_procsql,
			   @r_listavalori, @r_listaetichete, @r_initializare, @r_prompt, null, null, @r_formula, @detalii)
	end
	else
	begin
		update webConfigForm
		set Meniu=@r_meniu, Tip=@r_tip, Subtip=@r_subtip, Nume=@r_nume, TipObiect=@r_tip_obiect, DataField=@r_datafield, LabelField=@r_labelfield,
			Latime=@r_latime, Vizibil=@r_vizibil, Modificabil=@r_modificabil, ProcSQL=@r_procsql, ListaValori=@r_listavalori, ListaEtichete=@r_listaetichete,
			Initializare=@r_initializare, Prompt=@r_prompt, formula=@r_formula,ordine=(case when @r_ordine=@o_ordine then ordine else @r_ordine end),
			detalii=@detalii
		where Meniu=@o_meniu
			and isnull(Tip,'')=isnull(@o_tip,'') 
			and isnull(Subtip,'')=isnull(@o_subtip,'')
			and isnull(DataField,'')=isnull(@o_datafield,'')
	end


	exec wIaConfigMachete_Form @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	set @mesaj = error_message() + ' (wScriuConfigMachete_Form)'
	raiserror(@mesaj, 11, 1)
end catch
