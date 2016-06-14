-- procedura cauta urmatorul numar de document, tinand cont de datele din @parXML.  
-- parametrii @numar si @serie nu se mai folosesc si vor fi eliminati pe viitor  
-- rezultatul este returnat in @NrDoc si poate contine si seria, in functie de coloana 'SerieInNumar'  
create procedure wIauNrDocFiscale @parXML xml, @Numar int = null output, @serie varchar(9) = null output,@NrDoc varchar(20)=null output  
as  
  
set @Numar=0  
set @NrDoc=null  
  
declare @TipDocument varchar(3), @Utilizator varchar(10), @LM varchar(9), @Jurnal varchar(3), @Id int, @IdAnterior int,@documente int  
select @TipDocument=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(3)'), ''),  
  @Utilizator=isnull(@parXML.value('(/row/@utilizator)[1]', 'varchar(10)'), ''),  
  @LM=isnull(@parXML.value('(/row/@lm)[1]', 'varchar(9)'), ''),  
  @Jurnal=isnull(@parXML.value('(/row/@jurnal)[1]', 'varchar(3)'), ''),  
  @documente=isnull(@parXML.value('(/row/@documente)[1]', 'int'), 1)  
    
/* Daca nu exista tipul respectiv in tabela, pentru a nu complica implementatorii  
   vom insera o linie in docfiscale + asociere docfiscale pentru unitate*/  
  
  
if not exists (select 1 from docfiscale where TipDoc=@TipDocument)  
begin  
 declare @idAdaugat int  
   
 insert into docfiscale(TipDoc,Serie,NumarInf,NumarSup,UltimulNr)   
  values(@TipDocument,'','10000001','19999999','10000000')  
   
 select @idAdaugat=id from docfiscale where TipDoc=@TipDocument  
 insert into asocieredocfiscale(Id,Cod,Prioritate,TipAsociere)  
  values (@idAdaugat,'',0,'')  
end  
  
  
  
if @Utilizator=''   
 set @Utilizator=dbo.fIaUtilizator(null)  
  
select @LM=(case when @LM='' and cod_proprietate='LOCMUNCA' then valoare else @LM end),   
 @Jurnal=(case when @Jurnal='' and cod_proprietate='JURNAL' then valoare else @Jurnal end)  
from proprietati   
where (@LM='' or @Jurnal='') and tip='UTILIZATOR' and cod=@Utilizator and cod_proprietate in ('LOCMUNCA', 'JURNAL') and valoare<>''  
  
select @Id=0, @IdAnterior=-1  
  
while @Numar=0 and @Id<>@IdAnterior  
begin  
 set @IdAnterior=@Id  
   
 select top 1 @Id=d.Id  
 from docfiscale d  
 inner join asocieredocfiscale a on a.Id=d.Id  
 left outer join gruputiliz g on g.Id_utilizator=@utilizator  
 where   
 d.TipDoc=@TipDocument and d.UltimulNr between d.NumarInf-1 and d.NumarSup-1  
 and d.UltimulNr+@documente<=d.NumarSup  
 and (a.TipAsociere=''   
  or a.TipAsociere='L' and @LM<>'' and @LM like RTrim(a.Cod)+'%'   
  or a.TipAsociere='J' and a.Cod=@Jurnal   
  or a.TipAsociere='U' and a.Cod=@Utilizator   
  or a.TipAsociere='G' and g.Id_grup is not null and a.Cod=g.Id_grup)  
 order by a.prioritate, (case a.TipAsociere when 'U' then 0 when 'L' then 2 when 'J' then 4 when 'G' then 6 else 99 end), d.Serie  
   
 if @Id<>0  
 begin  
  set @Numar = 0  
    
  update docfiscale  
  set UltimulNr = UltimulNr + (case when UltimulNr >= NumarSup then 0 else @documente end),   
   @Numar = (case when UltimulNr >= NumarSup then @Numar else UltimulNr + 1 end),   
   @serie = rtrim(serie),  
   @NrDoc= (case when SerieInNumar=1 then rtrim(serie) else '' end)+  
    (case when UltimulNr >= NumarSup then null/*lasati cu null, pt. a nu se include seria fara numar in raspunsul final.*/   
     else ltrim(str(UltimulNr + 1)) end)  
  where Id=@Id  
 end  
 --exec IauNrDocFiscale @Id, @Numar output  
end  