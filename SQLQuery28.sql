-- reface bonurile in in tabela pozdoc, din tabela bp.  
create procedure wOPRefacACTE @sesiune varchar(50), @parXML xml   
as    
    declare @datajos datetime ,@datasus datetime, @listaGestiuni varchar(max),  
    @Subunitate varchar(1),@Tip varchar(2),@Numar varchar(10),@Cod varchar(10),@Data datetime ,  
    @Gestiune varchar(10),@Cantitate float ,@Pret_valuta float ,@Pret_de_stoc float,@utilizator varchar(50),@stergere bit,  
    @generare bit,@databon datetime ,@casabon varchar(10),@numarbon int ,@UID varchar(50),@userASiS varchar(50), @msgEroare varchar(max),  
    @codMeniu varchar(2),@vanzator varchar(20),@casamarcat varchar(20),@DetBon int, @NrDoc varchar(20)  
   
begin try  
raiserror('Aceasta operatie nu este actualizata. Contactati personalul Alfa Software.',11,1)  
/* de facut:  
 - mutarea din bp in bt sa mute si coloana idAntetBon, precum si restul coloanelor noi (lm, comanda, contract)  
 - se va face aici un cursor si se va apela wDescarcBon pentru fiecare bon -> wDescarcBon e gandita sa  
  functioneze atomic; daca sunt erori trebuie sa stearga tot ce a generat.  
 - toate selecturile sa foloseasca idAntetBon pentru identificare bon; acesta se trimite si la wDescarcBon.  
*/  
  
exec luare_date_par 'PO','DETBON',@DetBon output,0,''  
  
select @data=isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'01/01/1901'),  
  @numarbon=isnull(@parXML.value('(/parametri/@numar)[1]','int'),''),  
        /*-------- tratat pentru cele doua tipuri de codMeniu RF- Meniu; BC-Document*/  
  @datajos=isnull(@parXML.value('(/parametri/@datajos)[1]','datetime'),isnull(@data,'01/01/1901')),  
  @datasus=isnull(@parXML.value('(/parametri/@datasus)[1]','datetime'),isnull(@data,'01/01/1901')),  
     /*--------------------------*/   
  @gestiune =isnull(@parXML.value('(/parametri/@gestiune)[1]','varchar(10)'),''),  
  @codMeniu=isnull(@parXML.value('(/parametri/@codMeniu)[1]','varchar(10)'),''),  
  @vanzator=isnull(@parXML.value('(/parametri/@vanzator)[1]','varchar(10)'),''),  
  @casamarcat=isnull(@parXML.value('(/parametri/@casam)[1]','varchar(10)'),''),  
  @stergere=isnull(@parXML.value('(/parametri/@stergere)[1]','bit'),0),  
  @generare=isnull(@parXML.value('(/parametri/@generare)[1]','bit'),0)  
  
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output  
  
if @Gestiune=''   
 raiserror('wOPRefacACTE:Aceasta operatie se ruleaza pe o gestiune. Alegeti gestiunea dorita.',11,1)  
if exists (select 1 from proprietati where Tip='UTILIZATOR' and cod_proprietate in ('GESTIUNE','GESTPV') and  cod=@userASiS and Valoare<>'')  
 and @Gestiune not in (select valoare from proprietati where Tip='UTILIZATOR' and cod_proprietate in ('GESTIUNE','GESTPV') and  cod=@userASiS)  
begin   
 set @msgEroare='wOPRefacACTE:Nu aveti dreptul de a rula operatia pe aceasta gestiune (' + @Gestiune + ').'  
 raiserror(@msgeroare,11,1)  
end  
  
if @stergere=0 and @generare=1  
begin  
 set @msgEroare='wOPRefacACTE:Nu se poate rula generarea documentelor, daca nu bifati si stergerea documentelor existente.'  
 raiserror (@msgEroare,11,1)  
end  
         
if @stergere=1   
begin   
    if @codMeniu='BC' and @DetBon=0  
      raiserror('Bonul nu poate fi sters deoarece nu are detaliere!',16,1)  
    set @NrDoc=left(RTrim(CONVERT(varchar(4),@casamarcat))+right(replace(str(@numarbon),' ','0'),4), 8)  
    set @listaGestiuni = ';'+( select top 1 rtrim(val_alfanumerica) from par where Tip_parametru='PG' and Parametru=@Gestiune )+';'  
    delete from doc   
 where subunitate='1' and tip='AC' and stare=5 and  data between @datajos and @datasus  and  Cod_gestiune=@gestiune   
                    and Numar=(case @codMeniu when 'RF' then Numar else @NrDoc end)  
 delete from pozdoc   
 where subunitate='1' and tip='AC' and stare=5 and  data between @datajos and @datasus  and gestiune=@gestiune   
                    and Numar=(case @codMeniu when 'RF' then Numar else @NrDoc end)  
                      
    delete from doc where tip='AP' and Stare=5 and data between @datajos and @datasus   
   and Numar=(case @codMeniu when 'RF' then @NrDoc else Numar end)  
     
 delete from pozdoc where tip='AP' and Stare=5 and data between @datajos and @datasus   
   and Numar=(case @codMeniu when 'RF' then @NrDoc else Numar end)  
 /*and gestiune=@gestiune gestiunea e in antetbonuri*/  
  and exists (select 1 from antetBonuri a where a.Chitanta=0 and a.Factura=pozdoc.Numar and a.Gestiune=@Gestiune  
  and a.Data_facturii=pozdoc.Data and a.Tert=pozdoc.Tert  
  and not exists (select 1 from antetBonuri a2 where a.factura=a2.factura and a.data_facturii=a2.data_facturii and a.tert=a2.tert and a2.chitanta=1))  
       
 delete from pozdoc   
 where subunitate='1' and tip='TE' and stare=5 and data between @datajos and @datasus and gestiune_primitoare=@gestiune   
   --and Gestiune in (select top 1 [dbo].[fStrToken](val_alfanumerica, 1, ';') from par where Tip_parametru='PG' and Parametru=@Gestiune )  
   and charindex(';'+rtrim(gestiune)+';', @listagestiuni)>0   
   
   
end   
if @generare=1  
begin  
        insert into BT(Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura,   
    CodPLU, Cod_produs, Categorie, UM, Cantitate, Cota_TVA, Tva, Pret, Total, Retur, Inregistrare_valida, Operat,   
    Numar_document_incasare, Data_documentului, Loc_de_munca, Discount)  
   select Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, (case Tip when '20' then '21' else Tip end), Vinzator, Client, Cod_citit_de_la_tastatura,   
    CodPLU, Cod_produs, Categorie, UM, Cantitate, Cota_TVA, Tva, Pret, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount  
   from BP   
   where /*BP.factura_chitanta=1 and*/ data between @datajos and @datasus and loc_de_munca=@gestiune   
         and vinzator=(case @codMeniu when 'RF' then Vinzator else @vanzator end)   
         and Casa_de_marcat=(case @codMeniu when 'RF' then Casa_de_marcat else @casamarcat end)  
         and Numar_bon=(case @codMeniu when 'RF' then numar_bon else @numarbon end)  
           
   delete from BP   
   where /*BP.factura_chitanta=1 and*/ data between @datajos and @datasus and loc_de_munca=@gestiune  
      and vinzator=(case @codMeniu when 'RF' then Vinzator else @vanzator end)   
         and Casa_de_marcat=(case @codMeniu when 'RF' then Casa_de_marcat else @casamarcat end)  
         and Numar_bon=(case @codMeniu when 'RF' then numar_bon else @numarbon end)  
           
  --select * from pozdoc where data=@datajos and Gestiune=@Gestiune and tip='ac'  
   
 set @parXML= ( select @Gestiune gestiune, 1 dinRefaceri, @datajos dataJos, @datasus dataSus for xml raw )   
 exec wDescarcBon @sesiune ,@parXML  
end  
 select 'wOPRefacACTE:Refacere AC/TE efectuata cu succes!' as textMesaj for xml raw, root('Mesaje')  
end try  
begin catch  
 declare @eroare varchar(200)   
 set @eroare=ERROR_MESSAGE()+('wOPRefacACTE')  
 raiserror(@eroare, 16, 1)   
end catch  