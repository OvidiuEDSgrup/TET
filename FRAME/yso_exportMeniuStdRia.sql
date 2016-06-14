-- am facut procedura pt. ca sa o putem apela recursiv cand trebuie preluate si taburile.
-- se separa prin 'GO' fiecare tab
exec yso_exportMeniuStdRia @tipMacheta='D', @meniu='BO', @tip='BC', @subtip=''
GO
--***
if exists (select * from sysobjects where name ='yso_exportMeniuStdRia')
drop procedure yso_exportMeniuStdRia
go
--***
create procedure yso_exportMeniuStdRia @tipMacheta varchar(20),@meniu varchar(20), @tip varchar(20), @subtip varchar(20),
	@text varchar(max)=null output /* daca nu e null, rez se trimite aici(pt recursivitate) */
as
declare 
	@rez varchar(max), -- salvez in variabila pentru ca sa nu truncheze rezultatul.
	@tipMachetaE varchar(20)
	set @rez=''
	set nocount on
	set textsize 100000

if isnull(@subtip,'')='' --daca cer subtip....sigur nu imi trebuie script de stergere meniu si filtre
begin
	set @rez=isnull(@rez,'')+char(13)+ 'if exists (select 1 from webconfigmeniu where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''''
	+') begin raiserror(''Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu'',11,1) return end'
	set @rez=isnull(@rez,'')+char(13)+ '--delete from webconfigmeniu where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''''
	if @tipMacheta='E' 
	begin
		set @tipMacheta='D'
		set @tipMachetaE='E'
	end
	set @rez=isnull(@rez,'')+char(13)+ 'delete from webconfigfiltre where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''' and ('''+@tip+'''='''' or isnull(tip,'''')='''+@tip+''')'

end

set @rez=isnull(@rez,'')+char(13)+ 'delete from webconfiggrid where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''' and ('''+@tip+'''='''' or isnull(tip,'''')='''+@tip+''')'+' and ('''+@subtip+'''='''' or isnull(subtip,'''')='''+@subtip+''')'
set @rez=isnull(@rez,'')+char(13)+ 'delete from webconfigtipuri where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''' and ('''+@tip+'''='''' or isnull(tip,'''')='''+@tip+''')'+' and ('''+@subtip+'''='''' or isnull(subtip,'''')='''+@subtip+''')'
set @rez=isnull(@rez,'')+char(13)+ 'delete from webconfigform where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''' and ('''+@tip+'''='''' or isnull(tip,'''')='''+@tip+''')'+' and ('''+@subtip+'''='''' or isnull(subtip,'''')='''+@subtip+''')'
set @rez=isnull(@rez,'')+char(13)+ 'delete from webConfigTaburi where MeniuSursa='''+@meniu+''' and ('''+@tip+'''='''' or isnull(TipSursa,'''')='''+@tip+''')'

set @rez=isnull(@rez,'')+CHAR(13)

if isnull(@subtip,'')='' --daca cer subtip....sigur nu imi trebuie meniu
begin
	set @rez=isnull(@rez,'')+char(13)+'insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)'
	select @rez=isnull(@rez,'')+char(13)+'select top 0 null,null,null,null,null,null,null'
	select @rez=isnull(@rez,'')+char(13)+'union all select '''+convert(varchar(5),id)+''','''+isnull(Nume,'')+''','''+convert(varchar(5),idParinte)+''','''+isnull(Icoana,'')+''','''+isnull(TipMacheta,'')+''','''+isnull(Meniu,'')+''','''+isnull(Modul,'')+''''
	from webConfigStdMeniu where TipMacheta in (@tipMacheta,@tipMachetaE) and (@meniu is null or meniu=@meniu)
	/** Daca e tip macheta "E" acest lucru e tratat doar in webConfigMeniu, in rest e "D" ... **/
end

select @rez=isnull(@rez,'')+char(13)+char(13)+'insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) '
select @rez=isnull(@rez,'')+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null'
select @rez=isnull(@rez,'')+char(13)+'union all select '''+
isnull(IdUtilizator,'')+''','''+isnull(TipMacheta,'')+''','''+isnull(Meniu,'')+''','''+isnull(Tip,'')+''','''+isnull(Subtip,'')+''','''+isnull(convert(varchar(1),InPozitii),0)+''','''+isnull(NumeCol,'')+''','''+isnull(DataField,'')+''','''+isnull(TipObiect,'')+''','''+isnull(convert(varchar(10),Latime),1)+''','''+isnull(convert(varchar(10),Ordine),999)+''','''+isnull(convert(varchar(10),Vizibil),0)+''','''+convert(varchar(10),isnull(modificabil,0))+''','''+convert(varchar(500),isnull(formula,''))+''''
from webConfigStdGrid w where TipMacheta=@tipMacheta and (@meniu is null or meniu=@meniu) and (tip=@tip or @tip='' or TipMacheta='C') and (subtip=@subtip or @subtip='')

if isnull(@subtip,'')=''  --daca cer subtip....sigur nu imi trebuie filtre
begin
	select @rez=isnull(@rez,'')+char(13)+char(13)+'insert into webconfigFiltre (IdUtilizator, TipMacheta, Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) '
	select @rez=isnull(@rez,'')+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null'
	select @rez=isnull(@rez,'')+char(13)+'union all select '''+
	isnull(IdUtilizator,'')+''','''+isnull(TipMacheta,'')+''','''+isnull(Meniu,'')+''','''+isnull(Tip,'')+''','''+isnull(convert(varchar(10),Ordine),'')+''','''+convert(varchar(1),Vizibil)+''','''+
	isnull(TipObiect,'')+''','''+isnull(Descriere,'')+''','''+isnull(Prompt1,'')+''','''+isnull(DataField1,'')+''','''+convert(varchar(10),isnull(Interval,0))+''','''+isnull(Prompt2,'')+''','''+isnull(DataField2,'')+''''
	from webConfigStdFiltre where TipMacheta=@tipMacheta and (@meniu is null or meniu=@meniu) and (tip=@tip or @tip='')
end

select @rez=isnull(@rez,'')+char(13)+char(13)+'insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) '
select @rez=isnull(@rez,'')+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null'
select @rez=isnull(@rez,'')+char(13)+'union all select '''+
isnull(IdUtilizator,'')+''','''+isnull(TipMacheta,'')+''','''+isnull(Meniu,'')+''','''+isnull(Tip,'')+''','''+isnull(Subtip,'')+''','''+isnull(convert(varchar(10),Ordine),'0')+''','''+isnull(Nume,'')+''','''+isnull(Descriere,'')+''','''+isnull(TextAdaugare,'')+''','''+isnull(TextModificare,'')+''','''+isnull(ProcDate,'')+''','''+isnull(ProcScriere,'')+''','''+isnull(ProcStergere,'')+''','''+isnull(ProcDatePoz,'')+''','''+isnull(ProcScrierePoz,'')+''','''+isnull(ProcStergerePoz,'')+''','''+isnull(convert(varchar(2),Vizibil),'0')+''','''+isnull(Fel,'')+''','''+rtrim(isnull(procPopulare,''))+''','''+rtrim(isnull(tasta,''))+''''
from webConfigStdTipuri where TipMacheta=@tipMacheta and (@meniu is null or meniu=@meniu) and (tip=@tip or @tip='') and (subtip=@subtip or @subtip='')

select @rez=isnull(@rez,'')+char(13)+char(13)+'insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)'
select @rez=isnull(@rez,'')+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null'
select @rez=isnull(@rez,'')+char(13)+'union all select '''+
isnull(IdUtilizator,'')+''','''+isnull(TipMacheta,'')+''','''+isnull(Meniu,'')+''','''+isnull(Tip,'')+''','''+isnull(Subtip,'')+''','''+isnull(convert(varchar(10),Ordine),'')+''','''+isnull(Nume,'')+''','''+isnull(TipObiect,'')+
''','''+isnull(DataField,'')+''','''+isnull(LabelField,'')+''','''+isnull(convert(varchar(10),Latime),'')+''','''+convert(varchar(1),isnull(Vizibil,0))+''','''+
convert(varchar(1),isnull(Modificabil,0))+''','''+isnull(ProcSQL,'')+''','''+isnull(ListaValori,'')+''','''+isnull(ListaEtichete,'')+''','''+isnull(Initializare,'')+''','''+isnull(Prompt,'')+''','''+isnull(Procesare,'')+''','''+isnull(Tooltip,'')+''','''+convert(varchar(500),isnull(formula,''))+''''
from webConfigStdForm where TipMacheta=@tipMacheta and (@meniu is null or meniu=@meniu) and (tip=@tip or @tip='') and (subtip=@subtip or @subtip='')


if isnull(@subtip,'')=''  --daca cer subtip....sigur nu imi trebuie taburi
begin
	select @rez=isnull(@rez,'')+char(13)+char(13)+'insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)'
	select @rez=isnull(@rez,'')+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null'
	select @rez=isnull(@rez,'')+char(13)+'union all select '''+
	isnull(MeniuSursa,'')+''','''+isnull(TipSursa,'')+''','''+isnull(NumeTab,'')+''','''+isnull(Icoana,'')+''','''+isnull(TipMachetaNoua,'')+''','''+isnull(MeniuNou,'')+''','''+isnull(TipNou,'')+''','''+isnull(ProcPopulare,'')+
	''','''+isnull(convert(varchar(10),Ordine),'')+''','''+isnull(convert(varchar(10),Vizibil),'')+''''
	from webConfigStdTaburi where (@meniu is null or meniuSursa=@meniu) and (tipSursa=@tip or @tip='')

	declare @tipMachetaNou varchar(50), @meniuNou varchar(50), @tipNou varchar(50), @crs cursor, @f int, @tmpRez varchar(max),@numetab varchar(200), @semn int

	set @crs = cursor for 
		select	TipMachetaNoua,
				MeniuNou, 
				TipNou ,
				max(numetab)
		from webConfigStdTaburi 
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
			set @tmpRez=@tmpRez+char(13)+' if not exists (select 1 from webConfigTipuri where TipMacheta=''D'' and meniu='''+@meniuNou+''' and tip='''+@tipNou+''')'+CHAR(13)+' begin'
			set @semn=1
		end
		
		set @tipMachetaNou= case when @tipMachetaNou in ('PD','pozdoc') then 'D' when @tipMachetaNou in ('F') then 'C' else @tipMachetaNou end	
		
		if @tipMachetaNou in ('F')--daca tabul este de tip f- form , verificam daca exista configurari pentru tab pe baza de date tinta, si doar daca nu exista generam script de populare
		begin
			set @tmpRez=@tmpRez+char(13)+' if not exists (select 1 from webConfigTipuri where TipMacheta=''C'' and meniu='''+@meniuNou+''')'+CHAR(13)+' begin'
			set @semn=1
		end
		
		exec yso_exportMeniuStdRia @tipMacheta=@tipMachetaNou, @meniu=@meniuNou, @tip=@tipNou,@subtip='', @text = @tmpRez output
		
		set @rez = @rez + char(13)+ @tmpRez+case when @semn=1 then char(13)+' end' +CHAR(13) else ' ' end
		
		fetch next from @crs into @tipMachetaNou, @meniuNou, @tipNou,@numetab
		set @f=@@FETCH_STATUS
	end


	close @crs
	deallocate @crs
end
if @text is null
begin
	select @rez for xml path('')
end	
else
	set @text = @text + char(13) + @rez