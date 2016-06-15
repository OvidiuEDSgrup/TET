--***
create procedure wIaConfigMachete_Form (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @meniu varchar(20), @nume  varchar(100), @tip varchar(10), @subtip varchar(10), @nivel int,
		@fr_meniu varchar(20), @fr_tip varchar(20),  @fr_subtip varchar(20), @fr_nume varchar(100),
		@fr_vizibil varchar(3), @fr_modificabil varchar(3),
				--> parametri "@nec_" determina modul de filtrare: daca filtrul asociat contine doar spatii se vor aduce doar datele pt care campul corespunzator este necompletat, altfel se filtreaza cu like
		@nec_meniu bit, @nec_tip bit, @nec_subtip bit, @nec_nume bit

begin try

	set @meniu = isnull(@parXML.value('(/*/@meniu)[1]','varchar(20)'),'')
	set @tip = isnull(@parXML.value('(/*/@tip_m)[1]','varchar(10)'),'')
	set @subtip = isnull(@parXML.value('(/*/@subtip_m)[1]','varchar(10)'),'')
	set @nivel = @parXML.value('(/*/@nivel)[1]','int')

	select	@fr_meniu = isnull(@parXML.value('(/*/@fr_meniu)[1]','varchar(20)'),''),
		@fr_tip = isnull(@parXML.value('(/*/@fr_tip)[1]','varchar(20)'),''),
		@fr_subtip = isnull(@parXML.value('(/*/@fr_subtip)[1]','varchar(20)'),''),
		@fr_nume = isnull(@parXML.value('(/*/@fr_nume)[1]','varchar(100)'),''),
		@fr_vizibil = isnull(@parXML.value('(/*/@fr_vizibil)[1]','varchar(3)'),''),
		@fr_modificabil = isnull(@parXML.value('(/*/@fr_modificabil)[1]','varchar(3)'),'')

	select @nec_meniu=(case when rtrim(@fr_meniu)='' and @parXML.value('string-length(/*[1]/@fr_meniu)', 'int')>0 then 1 else 0 end),
		@nec_tip=(case when rtrim(@fr_tip)='' and @parXML.value('string-length(/*[1]/@fr_tip)', 'int')>0 then 1 else 0 end),
		@nec_subtip=(case when rtrim(@fr_subtip)='' and @parXML.value('string-length(/*[1]/@fr_subtip)', 'int')>0 then 1 else 0 end),
		@nec_nume=(case when rtrim(@fr_nume)='' and @parXML.value('string-length(/*[1]/@fr_nume)', 'int')>0 then 1 else 0 end),
		@fr_meniu='%' + @fr_meniu + '%',
		@fr_tip='%' + @fr_tip + '%',
		@fr_subtip='%' + @fr_subtip + '%',
		@fr_nume='%' + @fr_nume  + '%'

	if @nivel < 0
	begin
		set @mesaj = 'Nivel invalid.'
		raiserror(@mesaj,16,1)
	end
	
	set @fr_vizibil=(case when @fr_vizibil in ('da','1') then '1' when @fr_vizibil in ('nu','0') then '0' else '' end)
	set @fr_modificabil=(case when @fr_modificabil in ('da','1') then '1' when @fr_modificabil in ('nu','0') then '0' else '' end)
	
	select	wf.Meniu r_meniu,
			wf.Tip r_tip,
			wf.Subtip r_subtip,
			wf.Ordine r_ordine,
			wf.Nume r_nume,
			wf.TipObiect r_tip_obiect,
			wf.DataField r_datafield,
			wf.LabelField r_labelfield,
			wf.Latime r_latime,
			case when wf.Vizibil=1 then 'Da' else 'Nu' end r_vizibil_,
			wf.Vizibil r_vizibil,
			case when wf.Modificabil=1 then 'Da' else 'Nu' end r_modificabil_,
			wf.Modificabil r_modificabil,
			wf.ProcSQL r_procsql,
			wf.ListaValori r_listavalori,
			wf.ListaEtichete r_listaetichete,
			wf.Initializare	r_initializare,
			wf.Prompt r_prompt,
			wf.formula r_formula,
			(select wf.detalii for xml path(''), type)
	from	webconfigform wf
	where	(exists (select 1 from webConfigmeniu m where meniuparinte=@meniu and wf.Meniu=m.meniu) or wf.Meniu=@meniu)
			and (@tip='' or isnull(wf.Tip,'')=@tip)
			and (@subtip='' or isnull(wf.Subtip,'')=@subtip)
			and	(@nec_meniu=1 and rtrim(wf.meniu)='' or @nec_meniu=0 and wf.Meniu like @fr_meniu)
			and	(@nec_tip=1 and rtrim(wf.tip)='' or @nec_tip=0 and isnull(wf.Tip,'') like @fr_tip)
			and	(@nec_subtip=1 and rtrim(isnull(wf.subtip,''))='' or @nec_subtip=0 and isnull(wf.Subtip,'') like @fr_subtip)
			and	(@nec_nume=1 and rtrim(wf.nume)='' or @nec_nume=0 and wf.Nume like @fr_nume)
			and	(@fr_vizibil='' or convert(varchar(1),wf.Vizibil)=@fr_vizibil)
			and	(@fr_modificabil='' or convert(varchar(1),wf.Modificabil)=@fr_modificabil)
	order by wf.Meniu, isnull(wf.Tip,''), isnull(wf.Subtip,''), isnull(wf.Ordine,0)
	for xml raw
	
	select 1 as areDetaliiXml for xml raw,root('Mesaje')
end try

begin catch
	set @mesaj = error_message() + ' (wIaConfigMachete_Form)'
	raiserror(@mesaj, 11, 1)
end catch
