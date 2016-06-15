--***
create procedure wIaConfigMachete_Tipuri (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @meniu varchar(20), @tip varchar(10), @subtip varchar(10), @nivel int, @sursa varchar(100),
		@fp_meniu varchar(20), @fp_tip varchar(20), @fp_subtip varchar(20), @fp_nume varchar(100), @fp_vizibil varchar(3),
				--> parametri "@nec_" determina modul de filtrare: daca filtrul asociat contine doar spatii se vor aduce doar datele pt care campul corespunzator este necompletat, altfel se filtreaza cu like
		@nec_meniu bit, @nec_tip bit, @nec_subtip bit, @nec_nume bit,
		@fp_procedura varchar(500)
		
begin try

select
		@meniu = isnull(@parXML.value('(/*/@meniu)[1]','varchar(20)'),''),
		@tip = isnull(@parXML.value('(/*/@tip_m)[1]','varchar(10)'),''),
		@subtip = isnull(@parXML.value('(/*/@subtip_m)[1]','varchar(10)'),''),
		@sursa = @parXML.value('(/*/@sursa)[1]','varchar(100)'),
		@nivel = @parXML.value('(/*/@nivel)[1]','int'),
	@fp_meniu = isnull(@parXML.value('(/*/@fp_meniu)[1]','varchar(20)'),''),
	@fp_tip = isnull(@parXML.value('(/*/@fp_tip)[1]','varchar(20)'),''),
	@fp_subtip = isnull(@parXML.value('(/*/@fp_subtip)[1]','varchar(20)'),''),
	@fp_nume = isnull(@parXML.value('(/*/@fp_nume)[1]','varchar(100)'),''),
	@fp_procedura = isnull(@parXML.value('(/*/@fp_procedura)[1]','varchar(100)'),''),
	@fp_vizibil = isnull(@parXML.value('(/*/@fp_vizibil)[1]','varchar(3)'),'')
	
select
	@nec_meniu=(case when rtrim(@fp_meniu)='' and @parXML.value('string-length(/*[1]/@fp_meniu)', 'int')>0 then 1 else 0 end),
	@nec_tip=(case when rtrim(@fp_tip)='' and @parXML.value('string-length(/*[1]/@fp_tip)', 'int')>0 then 1 else 0 end),
	@nec_subtip=(case when rtrim(@fp_subtip)='' and @parXML.value('string-length(/*[1]/@fp_subtip)', 'int')>0 then 1 else 0 end),
	@nec_nume=(case when rtrim(@fp_nume)='' and @parXML.value('string-length(/*[1]/@fp_nume)', 'int')>0 then 1 else 0 end),
	@fp_meniu='%' + @fp_meniu + '%',
	@fp_tip='%' + @fp_tip + '%',
	@fp_subtip='%' + @fp_subtip + '%',
	@fp_nume='%' + @fp_nume + '%'
	
	set @fp_vizibil=(case when @fp_vizibil in ('da','1') then '1' when @fp_vizibil in ('nu','0') then '0' else '' end)

	if @nivel < 0
	begin
		set @mesaj = 'Nivel invalid.'
		raiserror(@mesaj,16,1)
	end

	/* Eventual se poate forta sa nu aduca tipurile pentru un meniu intreg */

	--if (@sursa='webConfigTipuri')
	begin
		select	wp.Meniu p_meniu,
				wp.Tip p_tip,
				wp.Subtip p_subtip,
				wp.Ordine p_ordine,
				wp.Nume p_nume,
				wp.Descriere p_descriere,
				wp.TextAdaugare p_textadaugare,
				wp.TextModificare p_textmodificare,
				wp.ProcDate p_procdate,
				wp.ProcScriere p_procscriere,
				wp.ProcStergere p_procstergere,
				wp.ProcDatePoz p_procdatepoz,
				wp.ProcScrierePoz p_procscrierepoz,
				wp.ProcStergerePoz p_procstergerepoz,
				wp.procPopulare p_procpopulare,
				wp.ProcInchidereMacheta p_procinchideremacheta,
				case when wp.Vizibil=1 then 'Da' else 'Nu' end p_vizibil_,
				wp.Vizibil p_vizibil,
				wp.Fel p_fel,
				wp.tasta p_tasta
		from	webconfigtipuri wp
		where	(wp.Meniu=@meniu  or exists (select 1 from webConfigmeniu m where m.meniuparinte=@meniu and m.meniu=wp.meniu))
			and (@tip='' or wp.Tip=@tip) 
			and (@subtip='' or wp.Subtip=@subtip)
			and	(@nec_meniu=1 and rtrim(isnull(wp.Meniu,''))='' or @nec_meniu=0 and isnull(wp.Meniu,'') like @fp_meniu)
			and	(@nec_tip=1 and rtrim(isnull(wp.Tip,''))='' or @nec_tip=0 and isnull(wp.Tip,'') like @fp_tip)
			and	(@nec_subtip=1 and rtrim(isnull(wp.Subtip,''))='' or @nec_subtip=0 and isnull(wp.Subtip,'') like @fp_subtip)
			and	(@nec_nume=1 and rtrim(isnull(wp.Nume,''))='' or @nec_nume=0 and isnull(wp.Nume,'') like @fp_nume)
			and	(@fp_vizibil='' or convert(varchar(1),wp.Vizibil)=@fp_vizibil)
			and (@fp_procedura=''
					or wp.ProcDate like @fp_procedura
					or wp.ProcScriere like @fp_procedura
					or wp.ProcStergere like @fp_procedura
					or wp.ProcDatePoz like @fp_procedura
					or wp.ProcScrierePoz like @fp_procedura
					or wp.ProcStergerePoz like @fp_procedura
					or wp.procPopulare like @fp_procedura
					or wp.ProcInchidereMacheta like @fp_procedura)
		order by wp.Meniu, wp.Tip, wp.Subtip, wp.Ordine
		for xml raw
	end
end try

begin catch
	set @mesaj = error_message() + ' (wIaConfigMachete_Tipuri)'
	raiserror(@mesaj, 11, 1)
end catch
