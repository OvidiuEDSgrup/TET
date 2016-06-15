--***
create procedure exportMeniuRia @tipMacheta varchar(20),@meniu varchar(20), @tip varchar(20), @subtip varchar(20),
	@text varchar(max)=null output /* daca nu e null, rez se trimite aici(pt recursivitate) */
as
declare @rez varchar(max) -- salvez in variabila pentru ca sa nu truncheze rezultatul.
set @rez=''
set nocount on
set textsize 100000
--declare @tipMacheta varchar(2),@meniu varchar(10), @tip varchar(2)
--set @tipMacheta='C'
--set @meniu='FF'
--set @tip=''

--select @tipMacheta, @meniu, @tip
if isnull(@subtip,'')='' --daca cer subtip....sigur nu imi trebuie script de stergere meniu si filtre
begin
	set @rez=isnull(@rez,'')+char(13)+ 'if exists (select 1 from webconfigmeniu where meniu='''+@meniu+''''
	+') begin raiserror(''Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu'',11,1) return end'
	set @rez=isnull(@rez,'')+char(13)+ '--delete from webconfigmeniu where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''''
	set @rez=isnull(@rez,'')+char(13)+ 'delete from webconfigfiltre where meniu='''+@meniu+''' and ('''+@tip+'''='''' or isnull(tip,'''')='''+@tip+''')'

end
set @rez=isnull(@rez,'')+char(13)+ 'delete from webconfiggrid where meniu='''+@meniu+''' and ('''+@tip+'''='''' or isnull(tip,'''')='''+@tip+''')'+' and ('''+@subtip+'''='''' or isnull(subtip,'''')='''+@subtip+''')'
set @rez=isnull(@rez,'')+char(13)+ 'delete from webconfigtipuri where meniu='''+@meniu+''' and ('''+@tip+'''='''' or isnull(tip,'''')='''+@tip+''')'+' and ('''+@subtip+'''='''' or isnull(subtip,'''')='''+@subtip+''')'
set @rez=isnull(@rez,'')+char(13)+ 'delete from webconfigform where meniu='''+@meniu+''' and ('''+@tip+'''='''' or isnull(tip,'''')='''+@tip+''')'+' and ('''+@subtip+'''='''' or isnull(subtip,'''')='''+@subtip+''')'
set @rez=isnull(@rez,'')+char(13)+ 'delete from webConfigTaburi where MeniuSursa='''+@meniu+''' and ('''+@tip+'''='''' or isnull(TipSursa,'''')='''+@tip+''')'

set @rez=isnull(@rez,'')+CHAR(13)
if isnull(@subtip,'')='' --daca cer subtip....sigur nu imi trebuie meniu
begin
	set @rez=isnull(@rez,'')+char(13)+'insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)'
	select @rez=isnull(@rez,'')+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null'
	select @rez=isnull(@rez,'')+char(13)+
	--'union all select '''+convert(varchar(5),id)+''','''+isnull(Nume,'')+''','''+convert(varchar(5),idParinte)+''','''+isnull(Icoana,'')+''','''+isnull(TipMacheta,'')+''','''+isnull(Meniu,'')+''','''+isnull(Modul,'')+''''
	'union all select '''+isnull(Meniu,'')+''','''+isnull(Nume,'')+''','''+isnull(MeniuParinte,'')+''','''+isnull(Icoana,'')+''','''+isnull(TipMacheta,'')+''','+convert(varchar(20),isnull(NrOrdine,0))+
		','''+isnull(Componenta,'')+''','''+isnull(Semnatura,'')+''','+isnull(''''+convert(varchar(max),Detalii)+'''','null')+','+convert(varchar(20),isnull(w.vizibil,0))
	from webConfigMeniu w where (@meniu is null or meniu=@meniu)
end

select @rez=isnull(@rez,'')+char(13)+char(13)+'insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) '
select @rez=isnull(@rez,'')+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null'
select @rez=isnull(@rez,'')+char(13)+'union all select '''+
isnull(w.Meniu,'')+''','''+isnull(w.Tip,'')+''','''+isnull(w.Subtip,'')+''','''+isnull(convert(varchar(1),w.InPozitii),0)+''','''+
	isnull(w.NumeCol,'')+''','''+isnull(w.DataField,'')+''','''+isnull(w.TipObiect,'')+''','''+isnull(convert(varchar(10),w.Latime),1)+''','''+
	isnull(convert(varchar(10),w.Ordine),999)+''','''+isnull(convert(varchar(10),w.Vizibil),0)+''','''+convert(varchar(10),isnull(w.modificabil,0))+''','''+convert(varchar(500),isnull(w.formula,''))+''''
from webConfigGrid w left join webconfigmeniu m on w.meniu=m.meniu where (@meniu is null or w.meniu=@meniu) and (w.tip=@tip or @tip='' or isnull(m.TipMacheta,'')='C') and (w.subtip=@subtip or @subtip='')

if isnull(@subtip,'')=''  --daca cer subtip....sigur nu imi trebuie filtre
begin
	select @rez=isnull(@rez,'')+char(13)+char(13)+'insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) '
	select @rez=isnull(@rez,'')+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null'
	select @rez=isnull(@rez,'')+char(13)+'union all select '''+
	isnull(w.Meniu,'')+''','''+isnull(w.Tip,'')+''','''+isnull(convert(varchar(10),w.Ordine),'')+''','''+convert(varchar(1),w.Vizibil)+''','''+
	isnull(w.TipObiect,'')+''','''+isnull(w.Descriere,'')+''','''+isnull(w.Prompt1,'')+''','''+isnull(w.DataField1,'')+''','''+convert(varchar(10),isnull(w.Interval,0))+''','''+
	isnull(w.Prompt2,'')+''','''+isnull(w.DataField2,'')+''''
	from webConfigFiltre w where (@meniu is null or w.meniu=@meniu) and (w.tip=@tip or @tip='')
end

select @rez=isnull(@rez,'')+char(13)+char(13)+'insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) '
select @rez=isnull(@rez,'')+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null'
select @rez=isnull(@rez,'')+char(13)+'union all select '''+
	isnull(w.Meniu,'')+''','''+isnull(w.Tip,'')+''','''+isnull(w.Subtip,'')+''','''+isnull(convert(varchar(10),w.Ordine),'0')+''','''+isnull(w.Nume,'')+''','''+
	isnull(w.Descriere,'')+''','''+isnull(w.TextAdaugare,'')+''','''+isnull(w.TextModificare,'')+''','''+isnull(w.ProcDate,'')+''','''+isnull(w.ProcScriere,'')+''','''+
	isnull(w.ProcStergere,'')+''','''+isnull(w.ProcDatePoz,'')+''','''+isnull(w.ProcScrierePoz,'')+''','''+isnull(w.ProcStergerePoz,'')+''','''+
	isnull(convert(varchar(2),w.Vizibil),'0')+''','''+isnull(w.Fel,'')+''','''+rtrim(isnull(w.procPopulare,''))+''','''+rtrim(isnull(w.tasta,''))+''''
from webConfigTipuri w where (@meniu is null or w.meniu=@meniu) and (w.tip=@tip or @tip='') and (w.subtip=@subtip or @subtip='')

select @rez=isnull(@rez,'')+char(13)+char(13)+'insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)'
select @rez=isnull(@rez,'')+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null'
select @rez=isnull(@rez,'')+char(13)+'union all select '''+
	isnull(w.Meniu,'')+''','''+isnull(w.Tip,'')+''','''+isnull(w.Subtip,'')+''','''+
	isnull(convert(varchar(10),w.Ordine),'')+''','''+isnull(w.Nume,'')+''','''+isnull(w.TipObiect,'')+''','''+isnull(w.DataField,'')+''','''+
	isnull(w.LabelField,'')+''','''+isnull(convert(varchar(10),w.Latime),'')+''','''+convert(varchar(1),isnull(w.Vizibil,0))+''','''+
	convert(varchar(1),isnull(w.Modificabil,0))+''','''+isnull(w.ProcSQL,'')+''','''+isnull(w.ListaValori,'')+''','''+isnull(w.ListaEtichete,'')+''','''+
	isnull(w.Initializare,'')+''','''+isnull(w.Prompt,'')+''','''+isnull(w.Procesare,'')+''','''+isnull(w.Tooltip,'')+''','''+convert(varchar(500),isnull(w.formula,''))+''''
from webConfigForm w
where (@meniu is null or w.meniu=@meniu) and (w.tip=@tip or @tip='') and (w.subtip=@subtip or @subtip='')


if isnull(@subtip,'')=''  --daca cer subtip....sigur nu imi trebuie taburi
begin
	select @rez=isnull(@rez,'')+char(13)+char(13)+'insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)'
	select @rez=isnull(@rez,'')+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null'
	select @rez=isnull(@rez,'')+char(13)+'union all select '''+
	isnull(MeniuSursa,'')+''','''+isnull(TipSursa,'')+''','''+isnull(NumeTab,'')+''','''+isnull(Icoana,'')+''','''+isnull(TipMachetaNoua,'')+''','''+isnull(MeniuNou,'')+''','''+isnull(TipNou,'')+''','''+isnull(ProcPopulare,'')+
	''','''+isnull(convert(varchar(10),Ordine),'')+''','''+isnull(convert(varchar(10),Vizibil),'')+''''
	from webConfigTaburi where (@meniu is null or meniuSursa=@meniu) and (tipSursa=@tip or @tip='')

	declare @tipMachetaNou varchar(50), @meniuNou varchar(50), @tipNou varchar(50), @crs cursor, @f int, @tmpRez varchar(max),@numetab varchar(200), @semn int

	set @crs = cursor for 
		select	TipMachetaNoua,
				MeniuNou, 
				TipNou ,
				max(numetab)
		from webConfigTaburi 
		where (@meniu is null or meniuSursa=@meniu) 
			and (tipSursa=@tip or @tip='')
			--and TipMachetaNoua <> @tipMacheta
			and MeniuNou <> @meniu
			and TipNou <> @tip
			--and TipMachetaNoua not in ('PD', 'Pozdoc')
		group by TipMachetaNoua,MeniuNou,TipNou
		
	open @crs
	fetch next from @crs into @tipMachetaNou, @meniuNou, @tipNou,@numetab
	set @f=@@FETCH_STATUS
	while @f=0 and @@NESTLEVEL < 30 -- sa nu intre in ceva bucla fara sfarsit
	begin
		set @semn=0
		set @tmpRez='--'
		set @tmpRez=isnull(@rez,'')+CHAR(13)
		set @tmpRez='--Tab: '+@numetab+' ---- '+ @tipMachetaNou+' ,'+@meniuNou+', '+ @tipNou 
		set @tipNou= case when @tipMachetaNou in ('C') then '' else @tipNou end
			
		if @tipMachetaNou in ('PD','Pozdoc')--daca tabul este de tip pozdoc , verificam daca exista configurari pentru tab pe baza de date tinta, si doar daca nu exista generam script de populare
		begin
			set @tmpRez=@tmpRez+char(13)+' if not exists (select 1 from webConfigTipuri t where exists (select 1 from webconfigmeniu w where w.meniu=t.meniu and w.TipMacheta=''D'') and meniu='''+@meniuNou+''' and tip='''+@tipNou+''')'+CHAR(13)+' begin'
			set @semn=1
		end
		
		set @tipMachetaNou= case when @tipMachetaNou in ('PD','pozdoc') then 'D' when @tipMachetaNou in ('F') then 'C' else @tipMachetaNou end	
		
		if @tipMachetaNou in ('F')--daca tabul este de tip f- form , verificam daca exista configurari pentru tab pe baza de date tinta, si doar daca nu exista generam script de populare
		begin
			set @tmpRez=@tmpRez+char(13)+' if not exists (select 1 from webConfigTipuri where exists (select 1 from webconfigmeniu w where w.meniu=t.meniu and w.TipMacheta=''D'') and meniu='''+@meniuNou+''')'+CHAR(13)+' begin'
			set @semn=1
		end
		
		exec exportMeniuRia @tipMacheta=@tipMachetaNou, @meniu=@meniuNou, @tip=@tipNou,@subtip='', @text = @tmpRez output
		
		set @rez = @rez + char(13)+ 'GO' + char(13) + @tmpRez+case when @semn=1 then char(13)+' end' +CHAR(13) else ' ' end
		
		fetch next from @crs into @tipMachetaNou, @meniuNou, @tipNou,@numetab
		set @f=@@FETCH_STATUS
	end


	close @crs
	deallocate @crs
end
if @text is null
begin
	declare @x xml
	select @x=(select @rez for xml path(''))
	select @rez=convert(varchar(max),@x)
	if charindex('&lt;',@rez)>0 or charindex('&gt;',@rez)>0
		select 'Atentie! Au fost inlocuite caractere la conversia in xml (< cu &lt; , respectiv > cu &gt;); trebuie inlocuite la loc!'
	select @x
end	
else
	set @text = @text + char(13) + @rez