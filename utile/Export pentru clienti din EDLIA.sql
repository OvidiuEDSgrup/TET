declare @rez varchar(max) -- salvez in variabila pentru ca sa nu truncheze rezultatul.
set @rez='--/*'
set nocount on
set textsize 100000
declare @tipMacheta varchar(2),@meniu varchar(10), @tip varchar(2), @subtip varchar(2)
set @tipMacheta='D'
set @meniu='CO'
set @tip='BK'
set @subtip=''

set @rez=@rez+char(13)+ 'if exists (select 1 from webconfigmeniu where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''''
+') begin raiserror(''Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu'',11,1) return end'
set @rez=@rez+char(13)+ '--*/delete from webconfigmeniu where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''''
set @rez=@rez+char(13)+ 'delete from webconfiggrid where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''' and ('''+@tip+'''='''' or isnull(tip,'''')='''+@tip+''')'+' and ('''+@subtip+'''='''' or isnull(subtip,'''')='''+@subtip+''')'
if @subtip=''
	set @rez=@rez+char(13)+ 'delete from webconfigfiltre where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''' and ('''+@tip+'''='''' or isnull(tip,'''')='''+@tip+''')'
set @rez=@rez+char(13)+ 'delete from webconfigtipuri where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''' and ('''+@tip+'''='''' or isnull(tip,'''')='''+@tip+''')'+' and ('''+@subtip+'''='''' or isnull(subtip,'''')='''+@subtip+''')'
set @rez=@rez+char(13)+ 'delete from webconfigform where tipMacheta='''+@tipMacheta+''' and meniu='''+@meniu+''' and ('''+@tip+'''='''' or isnull(tip,'''')='''+@tip+''')'+' and ('''+@subtip+'''='''' or isnull(subtip,'''')='''+@subtip+''')'

set @rez=@rez+char(13)+'insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)'
select @rez=@rez+char(13)+'select top 0 null,null,null,null,null,null,null'
select @rez=@rez+char(13)+'union all select '''+convert(varchar(5),id)+''','''+isnull(Nume,'')+''','''+convert(varchar(5),idParinte)+''','''+isnull(Icoana,'')+''','''+isnull(TipMacheta,'')+''','''+isnull(Meniu,'')+''','''+isnull(Modul,'')+''''
from webConfigMeniu where TipMacheta=@tipMacheta and (@meniu is null or meniu=@meniu)

select @rez=@rez+char(13)+char(13)+'insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare) '
select @rez=@rez+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null'
select @rez=@rez+char(13)+'union all select '''+
isnull(IdUtilizator,'')+''','''+isnull(TipMacheta,'')+''','''+isnull(Meniu,'')+''','''+isnull(Tip,'')+''','''+isnull(Subtip,'')+''','''+isnull(convert(varchar(10),Ordine),'0')+''','''+isnull(Nume,'')+''','''+isnull(Descriere,'')+''','''+isnull(TextAdaugare,'')+''','''+isnull(TextModificare,'')+''','''+isnull(ProcDate,'')+''','''+isnull(ProcScriere,'')+''','''+isnull(ProcStergere,'')+''','''+isnull(ProcDatePoz,'')+''','''+isnull(ProcScrierePoz,'')+''','''+isnull(ProcStergerePoz,'')+''','''+isnull(convert(varchar(2),Vizibil),'0')+''','''+isnull(Fel,'')+''','''+rtrim(isnull(procPopulare,''))+''''
from webConfigTipuri where TipMacheta=@tipMacheta and (@meniu is null or meniu=@meniu) and (tip=@tip or @tip='') and (subtip=@subtip or @subtip='')
order by isnull(IdUtilizator,''), TipMacheta, Meniu, Tip, Subtip, Ordine

if @subtip=''
begin
	select @rez=@rez+char(13)+char(13)+'insert into webconfigFiltre (IdUtilizator, TipMacheta, Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) '
	select @rez=@rez+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null'
	select @rez=@rez+char(13)+'union all select '''+
	isnull(IdUtilizator,'')+''','''+isnull(TipMacheta,'')+''','''+isnull(Meniu,'')+''','''+isnull(Tip,'')+''','''+isnull(convert(varchar(10),Ordine),'')+''','''+convert(varchar(1),Vizibil)+''','''+
	isnull(TipObiect,'')+''','''+isnull(Descriere,'')+''','''+isnull(Prompt1,'')+''','''+isnull(DataField1,'')+''','''+convert(varchar(10),isnull(Interval,0))+''','''+isnull(Prompt2,'')+''','''+isnull(DataField2,'')+''''
	from webConfigFiltre where TipMacheta=@tipMacheta and (@meniu is null or meniu=@meniu) and (tip=@tip or @tip='') 
	order by isnull(IdUtilizator,''), TipMacheta, Meniu, Tip, Ordine, DataField1
end

select @rez=@rez+char(13)+char(13)+'insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, Ordine, NumeCol, DataField, TipObiect, Latime, Vizibil, Modificabil) '
select @rez=@rez+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null'
select @rez=@rez+char(13)+'union all select '''+
isnull(IdUtilizator,'')+''','''+isnull(TipMacheta,'')+''','''+isnull(Meniu,'')+''','''+isnull(Tip,'')+''','''+isnull(Subtip,'')+''','''+convert(varchar(1),InPozitii)+''','''+convert(varchar(10),Ordine)+''','''+NumeCol+''','''+DataField+''','''+TipObiect+''','''+convert(varchar(10),Latime)+''','''+convert(varchar(10),Vizibil)+''','''+convert(varchar(10),modificabil)+''''
from webConfigGrid w where TipMacheta=@tipMacheta and (@meniu is null or meniu=@meniu) and (tip=@tip or @tip='') and (subtip=@subtip or @subtip='')
order by isnull(IdUtilizator,''), TipMacheta, Meniu, Tip, Subtip, InPozitii, Ordine, DataField

select @rez=@rez+char(13)+char(13)+'insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip)'
select @rez=@rez+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null'
select @rez=@rez+char(13)+'union all select '''+
isnull(IdUtilizator,'')+''','''+isnull(TipMacheta,'')+''','''+isnull(Meniu,'')+''','''+isnull(Tip,'')+''','''+isnull(Subtip,'')+''','''+isnull(convert(varchar(10),Ordine),'')+''','''+isnull(Nume,'')+''','''+isnull(TipObiect,'')+
''','''+isnull(DataField,'')+''','''+isnull(LabelField,'')+''','''+isnull(convert(varchar(10),Latime),'')+''','''+convert(varchar(1),isnull(Vizibil,0))+''','''+
convert(varchar(1),isnull(Modificabil,0))+''','''+isnull(ProcSQL,'')+''','''+isnull(ListaValori,'')+''','''+isnull(ListaEtichete,'')+''','''+isnull(Initializare,'')+''','''+isnull(Prompt,'')+''','''+isnull(Procesare,'')+''','''+isnull(Tooltip,'')+''''
from webConfigForm where TipMacheta=@tipMacheta and (@meniu is null or meniu=@meniu) and (tip=@tip or @tip='') and (subtip=@subtip or @subtip='')
order by isnull(IdUtilizator,''), TipMacheta, Meniu, Tip, Subtip, Ordine, DataField

select @rez for xml path('')