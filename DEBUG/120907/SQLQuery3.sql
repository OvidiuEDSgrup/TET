--***  
create procedure wUnCodNomenclator @sesiune varchar(50), @parXML XML  
as  
set transaction isolation level read uncommitted  
  
declare @returnValue int  
if exists(select * from sysobjects where name='wUnCodNomenclatorSP' and type='P')        
begin  
 exec @returnValue = wUnCodNomenclatorSP @sesiune,@parXML  
 return @returnValue   
end  
  
declare @cod varchar(100), @categoriePret int, @cantitate decimal(12,3), @vanzareFaraStoc bit, @ruleazaSelect bit, @barcode varchar(50), @UM varchar(3),  
  @utilizator varchar(10),@gestiuneBon varchar(13), @esteStoc bit, @mesaj varchar(max), @tipNomencl varchar(10), @stocTotal float, @codUM varchar(3),  
  @pret float, @discount float, @tert varchar(50), @comanda varchar(20), @xmlPret xml, @listaGestiuni varchar(max), @GESTPVbon varchar(100),  
  @coefConversie float, @codInitial varchar(50), @xmlFinal xml, @cantitateStr varchar(50), @denumire varchar(50), @cotaTvaStr varchar(50),  
  @trebuieCantarit bit  
  
select @cod=ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(100)'), ''),   
  @codInitial=@parXML.value('(/row/@codInitial)[1]', 'varchar(20)'),   
  @categoriePret=ISNULL(@parXML.value('(/row/@categoriePret)[1]', 'int'), '1'),   
  @tert=ISNULL(@parXML.value('(/row/tert/@cod)[1]', 'varchar(50)'), ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(50)'),'')),   
  @comanda=ISNULL(@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), ''),   
  @cantitate=@parXML.value('(/row/@cantitate)[1]', 'decimal(12,3)'),  
  @GESTPVbon=ISNULL(@parXML.value('(/row/@GESTPV)[1]', 'varchar(100)'),'') -- gestiunea bonului - poate fi setata si din detalii...  
  
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null  
 return -1  
  
/* determinare gestiune: daca nu e trimisa in parXML, se ia din proprietatea GESTPV de pe user.   
Se atasaza si gestiunile din care se face transfer automat, pentru calcularea stocului */  
set @gestiuneBon= (case when @GESTPVbon<>'' then @GESTPVbon else dbo.wfProprietateUtilizator('GESTPV', @utilizator) end)  
set @listaGestiuni= dbo.wfListaGestiuniAtasatePV(@gestiuneBon)  
-- legacy: set @listaGestiuni= rtrim(@gestiuneBon)+';'+isnull(rtrim((select val_alfanumerica from par where tip_parametru='PG' and parametru=@gestiuneBon)),'')  
  
  
/* categorie pret in ordine   
 1. Categoria Documentului/Tertului, (din PVria vine categoria documentului daca este configurabila in detalii, sau a tertului, daca se alege un tert cu alta categorie.)  
 2. Categoria gestiunii  */  
if @categoriePret=0 or @categoriePret is null   
 set @categoriePret=1  
if @categoriePret=1 /* din PVria vine implicit 1 sau categoria tertului */  
 set @categoriePret=(select valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestiuneBon)  
  
/* verific daca am scanat un cod de bare si identific codul de produs */  
select @barcode=rtrim(cod_de_bare) , @cod=rtrim(Cod_produs), @codUM=um  
from codbare where Cod_de_bare=@cod and not exists (select 1 from nomencl where cod=@cod) -- daca s-a introdus un cod de nomenclator sa nu mai caute dupa cod bare  
  
if not exists ( select 1 from nomencl where cod = @cod ) and exists ( select 1 from nomencl where cod = @codInitial )  
 set @cod=@codInitial /*cod initial este trimis daca se detecteaza * sau x in cod */  
  
if not exists ( select 1 from nomencl where cod = @cod )  
begin   
 if LEN(@cod)>20 and exists (select * from CarduriFidelizare c where c.UID=@cod)   
 begin  
  set @xmlFinal=(select rtrim(@cod) as uidCardFidelizare for xml raw)  
  exec wIaPuncteCardFidelizare @sesiune=@sesiune, @parXML=@xmlFinal  
    
  return  
 end  
 else  
 begin  
  set @mesaj='Codul introdus ('+ @cod +') nu poate fi gasit.'  
  raiserror(@mesaj,11,1)  
  return -1  
 end  
end  
  
-- verific daca trebuie trimisa cota TVA=0 - a se pastra corelat cu conditia din wDescarcBon  
declare @tipTVA int  
if @tert='' or (select it.grupa13 from infotert it where it.subunitate='1' and it.tert=@tert and it.identificator='')='1'  
 set @tipTVA=0  
else  
 set @tipTVA=isnull((select convert(int, left(n.tip_echipament,1)) from nomencl n where n.Cod=@cod),0)  
  
/* formare pret */  
select @pret=null, @discount=null,  
  @xmlPret= (select @cod cod, @tert tert, @comanda comandalivrare, @categoriePret categpret, (case when @tipTVA=1 then 0 else 1 end) iaupretamanunt for xml raw )  
exec dbo.wIaPretDiscount @xmlPret, @pret output, @discount output  
  
/* validare tip nomencl si calculare pret in alte UM, folosind coef. conversie */  
-- Ghita, 27.06.2011: am citit UM de stoc, am modificat cantitatea sa fie in UM de stoc  
select @tipNomencl=tip, @UM=UM,--rtrim((case isnull(@codUM,1) when 2 then UM_1 when 3 then UM_2 else UM end)),  
 @coefConversie= (case isnull(@codUM,1) when 1 then 1 when 2 then Coeficient_conversie_1 when 3 then Coeficient_conversie_2 else 1 end),  
 --@pret=@pret*@coefConversie  
 @cantitate=@cantitate*@coefConversie,  
 @denumire=rtrim(n.denumire),   
 @cotaTvaStr=convert(varchar(50),convert(decimal(12,2),(case when @tipTVA=1 then 0 else convert(decimal(12,2),cota_tva) end)))  
from nomencl n where cod=@cod   
  
if @tipNomencl not in ('A', 'M', 'P', 'S')   
begin  
 set @mesaj='Tipul de nomenclator:'+@tipNomencl+' nu este permis la vanzare.'  
 raiserror(@mesaj,11,1)  
 return -1  
end  
  
set @trebuieCantarit = (case when @UM='kg' then 1 else 0 end)  
  
/* setarea 'GE','FARASTOC' = pot face vanzare 'in rosu'(fara sa existe pe stoc respectivele produse) */  
exec luare_date_par 'GE','FARASTOC', @vanzareFaraStoc output, null, null  
  
/* validare cod: verifica daca se poate vinde fara stoc. Daca nu e voie, valideaza stocul pentru  
   gestiunile atasate. Pentru cant<=0 nu afisez eroare, dar calculez si trimit stocMaxim. */  
if @vanzareFaraStoc=0 and @tipNomencl<>'S'  
begin   
 /* calculez stoc total pe gestiunile valide */  
 set @stocTotal= ISNULL(( select SUM(stoc) from stocuri s inner join dbo.split(@listagestiuni,';') lg on s.Cod_gestiune=lg.Item  
  where Subunitate='1' and cod=@cod ),0)  
  
 if @stocTotal<=0.00999 and @cantitate>0.00  
 begin  
  set @mesaj='Produsul selectat nu este pe stoc in ' +   
   (case when @gestiuneBon+';'=@listaGestiuni then 'gestiunea '+rtrim(@gestiuneBon)   
    else 'gestiunile '+REPLACE(@listaGestiuni,';',',') end) + '.'  
  raiserror(@mesaj,11,1)  
  return -1  
 end  
   
 /* pentru vanzare in alte UM, cantitatea implicita nu e obligatoriu 1 */  
 if @UM<>'BUC' and @stocTotal>0.0001 and @stocTotal<1.00 and @cantitate=1.00  
  set @cantitate=round(@stoctotal,3)  
   
 if @stocTotal-@cantitate<-0.0001 /*isnull(@coefConversie,1)*/ and @cantitate>0.00 /*nu validez cantitate, daca se adauga produs storno.*/  
 begin  
  set @mesaj='Stocul maxim disponibil este de '+ convert(varchar,CONVERT(decimal(12,2),@stocTotal))+'.'+  
   (case when @coefConversie<>1 then '(stocul maxim este afisat in UM principala)' else '' end)  
  raiserror(@mesaj,11,1)  
  return -1  
 end  
end  
set @cantitateStr=replace(rtrim(replace(replace(rtrim(replace(@cantitate,'0',' ')),' ','0'),'.',' ')),' ','.')  
  
set @xmlFinal=  
(select @cod as cod, @denumire as denumire, @UM um, @codUM codUM, @cotaTvaStr as cotatva, @barcode as barcode,  
 convert(decimal(12,2),@pret) as pretcatalog, convert(decimal(12,2),@discount) as discount, @tipNomencl as tip,   
 @cantitateStr as cantitate,  
 @trebuieCantarit as trebuieCantarit,  
 convert(decimal(12,2),@stocTotal) as stocMaxim,  
 null as cotatvaincasam /* identificator cota TVA se poate trimite din SP. E mai puternic decat setarile de pe statii.   
        (case when cota_tva=24 then 1 when Cota_TVA=9 then 2 else 0 end)*/,  
 null as zecimaleCantitate /* pt. a permite alt numar de zecimale la cantitate,   
    din macheta pt. schimbare cantitate - momentan in casuta cu Cod permitem oricate zecimale... */   
 for xml raw)  
  
/* procedura specifica va insera atribute in xml-ul primit in parametrul 3 */  
if exists (select 1 from sysobjects where name ='formeazaPretMinimSP') /* procedura legacy folosita (cred) numai la pragmatic */  
 exec formeazaPretMinimSP @sesiune=@sesiune, @parXML=@parXML, @xmlFinal=@xmlFinal output  
  
/* procedura specifica va insera atribute in xml-ul primit in parametrul 3.  
 in @parXML se trimite parametrul din PVria, iar @xmlFinal este generat in aceasta procedura   
*/  
if exists (select 1 from sysobjects where name ='wUnCodNomenclatorSP2')  
 exec wUnCodNomenclatorSP2 @sesiune=@sesiune, @parXML=@parXML, @xmlFinal=@xmlFinal output  
  
select @xmlFinal  
  
  
return 0 