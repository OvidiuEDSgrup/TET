/*  
 Procedura cauta si returneaza un numar de document valid, tinand cont de datele din @parXML.  
 Rezultatul este returnat in 3 variabile: @serie, @numar si @NrDoc.  
  @serie(varchar) returneaza seria documentului;  
  @numar(int) returneaza numarul de document;  
  @NrDoc(varchar) returneaza tot un numar de document, dar in functie de coloana 'SerieInNumar':  
     daca SerieInNumar=1 atunci se returneaza @serie+@numar  
     altfel se returneaza doar @numar.  
   
 Un utilizator poate avea asociate mai multe plaje de documente pentur acelasi tip de document.  
 Filtrat pe tipul de document cautat (Avize, Receptii, Etc.), procedura parcurge toate plajele asociate   
 in functie de prioritatea configurata pentru fiecare plaja.  
  
 Daca se primeste in variabila @idplajaceruta un ID valid procedura va returna numarul de document din exact acea plaja,   
 fara sa tina cont de celelalte conditii.  
   
 Pentru fiecare plaja, se verifica mai intai daca exista numere de document care au fost rezervate dar nu s-au folosit   
 in perioada rezervata. Daca nu exista rezervari, se returneaza urmatorul numar din plaja, iar plaja este incrementata.  
   
*/  
create procedure wIauNrDocFiscale @parXML xml, @Numar int = null output, @serie varchar(9) = null output,@NrDoc varchar(20)=null output,@idPlaja int=null output  
as  
  
set @Numar=0  
set @NrDoc=null  
declare @TipDocument varchar(3), @Utilizator varchar(10), @LM varchar(9), @Jurnal varchar(3), @documente int, @serieInNumar int, @idplajaceruta int  
  
select   
 @TipDocument=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(3)'), ''),  
 @Utilizator=isnull(@parXML.value('(/row/@utilizator)[1]', 'varchar(10)'), ''),  
 @LM=isnull(@parXML.value('(/row/@lm)[1]', 'varchar(9)'), ''),  
 @Jurnal=isnull(@parXML.value('(/row/@jurnal)[1]', 'varchar(3)'), ''),  
 @documente=isnull(@parXML.value('(/row/@documente)[1]', 'int'), 1),  
 @idplajaceruta=@parXML.value('(/row/@idplaja)[1]', 'int')  
   
  
/* Daca nu exista tipul respectiv in tabela, pentru a nu complica implementatorii  
   vom insera o linie in docfiscale + asociere docfiscale pentru unitate*/  
if not exists (select 1 from docfiscale where TipDoc=@TipDocument)  
begin  
 declare @idAdaugat int  
   
 insert into docfiscale(TipDoc,Serie,NumarInf,NumarSup,UltimulNr)   
  values(@TipDocument,'','10000001','19999999','10000000')  
   
 select @idPlaja=id from docfiscale where TipDoc=@TipDocument  
 insert into asocieredocfiscale(Id,Cod,Prioritate,TipAsociere)  
  values (@idPlaja,'',0,'')  
end  
  
/** citesc user daca nu a fost trimis in XML **/  
if @Utilizator=''   
 set @Utilizator=dbo.fIaUtilizator(null)  
  
/* Aici pot fi mai multe locuri de munca atasate userului. Procedura momentan nu trateaza mai multe... */  
select @LM=(case when @LM='' and cod_proprietate='LOCMUNCA' then valoare else @LM end),   
 @Jurnal=(case when @Jurnal='' and cod_proprietate='JURNAL' then valoare else @Jurnal end)  
from proprietati   
where (@LM='' or @Jurnal='') and tip='UTILIZATOR' and cod=@Utilizator and cod_proprietate in ('LOCMUNCA', 'JURNAL') and valoare<>''  
  
/* Ne asiguram ca nu dam la 2 oameni acelasi numar de document. */  
begin tran ianr  
 /* Identificam plaja valida conform criteriilor si prioritatilor stabilite.  
  Tot aici citim si datele plajei(serie & serie in numar) - plaja este deja valida. */  
 select top 1   
  @idPlaja=d.Id,  
  @serieInNumar=SerieInNumar,  
  @serie=RTRIM(serie)  
 from docfiscale d  
 inner join asocieredocfiscale a on a.Id=d.Id  
 left outer join gruputiliz g on g.Id_utilizator=@utilizator  
 where   
 d.TipDoc=@TipDocument and d.UltimulNr between d.NumarInf-1 and d.NumarSup-1  
 and d.UltimulNr+@documente<=d.NumarSup  
 and (  
   (  
    (  
     a.TipAsociere=''   
     or a.TipAsociere='L' and @LM<>'' and @LM like RTrim(a.Cod)+'%'   
     or a.TipAsociere='J' and a.Cod=@Jurnal   
     or a.TipAsociere='U' and a.Cod=@Utilizator   
     or a.TipAsociere='G' and g.Id_grup is not null and a.Cod=g.Id_grup  
    )  
    and @idplajaceruta is null   
   )   
   or  (@idplajaceruta is not null and d.Id=@idplajaceruta)  
  )  
 order by a.prioritate, (case a.TipAsociere when 'U' then 0 when 'L' then 2 when 'J' then 4 when 'G' then 6 else 99 end), d.Serie  
   
 /* daca nu am gasit plaja, returnam 0 la toate. */  
 if isnull(@idPlaja,0)=0  
 begin  
  select @Numar=0,@NrDoc='',@serie='',@idPlaja=0  
  rollback tran ianr  
  return  
 end  
  
 /*   
  Verificam daca a expirat rezervarea la vre-un numar rezervat din plaja curenta.  
  daca @documente e mai mare, nu mai cautam in rezervari - altfel s-ar incaleca numerele.  
 */  
 if @documente=1  
  select top 1 @Numar=numar   
  from docfiscalerezervate   
  where idPlaja=@idPlaja and getdate()>expirala  
  
 /* Daca am gasit numarul in plaja de documente rezervate, il returnez acesta */  
 if @Numar>0  
  delete from docfiscalerezervate   
   where idPlaja=@idPlaja and getdate()>expirala and numar=@numar  
 else -- actualizez plaja  
  update docfiscale  
   set UltimulNr = UltimulNr + @documente,  
    @Numar = UltimulNr + 1  
  where Id=@idPlaja  
  
 /* Formez @NrDoc. */  
 set @NrDoc=(case when @serieInNumar=1 then rtrim(@serie) else '' end)+ltrim(str(@Numar))  
   
commit tran ianr