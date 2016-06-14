drop trigger tr_ValidPozdoc 
go
--***  
create  trigger tr_ValidPozdoc on pozdoc for insert,update,delete NOT FOR REPLICATION as  
DECLARE @nrRanduri int,@mesaj varchar(255)  
SET @nrRanduri=@@ROWCOUNT  
IF @nrRanduri=0   
 RETURN  
-- Ghita, 27.04.2012: acest trigger ar trebui sa se raporteze doar la cataloage, nu si la tabelele sinteza (acestea se actualizeaza prin triggere si nu se stie daca inainte sau dupa verificare)  
begin try   
 if UPDATE(tert) --Verificam consistenta tertilor pe anumite tipuri, la fel va fi pe celelalte campuri  
 begin  
  if (select min(case when inserted.tip in ('RM','RS','AP','AS') and terti.tert is null then '' else 'corect' end)  
  from inserted   
   left outer join terti on inserted.Subunitate=terti.Subunitate and inserted.Tert=terti.tert  
  where inserted.subunitate<>'intrastat')=''  
    
   raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Tert neintrodus sau inexistent in catalogul de terti!',16,1)  
 end   
   
 if update(cod) --Verificam consistenta codurilor  
 begin  
  if (select min(case when inserted.Tip NOT in ('RP','RQ') and n.cod is null then '' else 'corect' end)  
  from inserted   
   left outer join nomencl n on inserted.cod=n.cod  
  where inserted.subunitate<>'intrastat')=''  
   raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Cod neintrodus sau inexistent in nomenclator!',16,1)  
 end     
  
 /* Daca exista inventar deschis nu se permite operarea de documente pe acea gestiune pe o data anterioare deschiderii inventarului    */  
 IF EXISTS (  
   SELECT 1  
   FROM antetinv at  
   INNER JOIN inserted ins ON at.gestiune = ins.Gestiune  
    AND ins.Data <= at.Data  
    AND at.Blocat IN (0, 1)  
   )  
 BEGIN  
  RAISERROR (' Eroare operare (pozdoc.tr_ValidPozdoc): Exista inventar deschis pe gestiunea si data operata!', 16, 1  
    )  
 END  
  
 if UPDATE(gestiune) --se pot citi proprietati pe gestiune  
 begin  
  declare @userASiS varchar(50), @ObInvPeLocM int  
  set @userASiS=dbo.fIaUtilizator(null)  
  exec luare_date_par 'GE','FOLLOCM', @ObInvPeLocM output, 0, ''  
  -- mai jos am verificat daca pe pozitile de I/E gestiunile sunt corecte  
  if (select min(case when (inserted.Tip_miscare in ('I','E') and gestiuni.Cod_gestiune is null and inserted.Tip not in('PF','AF','CI','RS'))   
   or (inserted.Tip in ('PF','AF','CI') and p.Marca is null) --in cazul PF....etc in capul gestiune se tine marca=> validam marca  
   or (inserted.tip='TE' and g1.Cod_gestiune is null)  
   or (inserted.tip in ('DF','PF')  and (p1.Marca is null and @ObInvPeLocM = 0))  -- in cazul PF,DF trebuie validata marca primitoare in functie de setarea care permite darea in fol catre un loc m  
     
   then '' else 'corect' end)  
    from inserted   
    left outer join gestiuni on inserted.Subunitate=gestiuni.Subunitate and inserted.Gestiune=gestiuni.Cod_gestiune  
    left outer join gestiuni g1 on inserted.Subunitate=g1.Subunitate and inserted.Gestiune_primitoare=g1.Cod_gestiune and inserted.Tip='TE'  
    left outer join personal p on inserted.Gestiune=p.Marca and inserted.Tip in ('PF','AF','CI')  
    left outer join personal p1 on inserted.Gestiune_primitoare=p1.Marca and inserted.Tip in ('PF','DF') )=''  
   raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Gestiune/Marca sau Gestiune/Marca primitoare invalida!',16,1)  
  
  --Pentru gestiune ca si proprietate utilizator  
  if (select max(valoare) from proprietati pr where pr.Tip='UTILIZATOR' and pr.Cod_proprietate='GESTIUNE' and pr.cod=@userASiS and valoare<>'') is not null  
    and exists (select * from inserted   
    left outer join proprietati pr on pr.Tip='UTILIZATOR' and pr.Cod_proprietate='GESTIUNE' and pr.cod=@userASiS and pr.Valoare=inserted.Gestiune  
    left outer join proprietati pp on pp.Tip='UTILIZATOR' and pp.Cod_proprietate='GESTIUNE' and pp.cod=@userASiS and pp.Valoare=inserted.Gestiune_primitoare   
    where Tip_miscare in ('I','E') and inserted.tip<>'TE' and pr.Valoare is null   
     or inserted.tip='TE' and pr.Valoare is null and pp.Valoare is null)  
   raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Nu aveti drepturi pe aceasta gestiune!',16,1)  
 end  
   
 -- Ghita, 27.04.2012: aceasta validare se va face dinspre triggerele "docStoc", ca sa nu depind de ordinea de executie a triggerelor  
 if 1=0 and (UPDATE(pret_de_stoc) or UPDATE(cont_de_stoc) or UPDATE(cont_corespondent))  
 begin  
    /*   
  **  Validare pret sau cont pt tip_miscare='I' ex: AI,AE   
  */  
  if exists (select 1 from inserted i    
  inner join stocuri s on i.subunitate=s.subunitate and s.cod_gestiune=i.gestiune and   
        s.cod=i.cod and s.cod_intrare=i.cod_intrare and i.Tip_miscare='I'  
  where ((s.Stoc_initial = 0 and s.Intrari != i.cantitate) or (s.Stoc_initial != 0 and s.intrari = i.Cantitate) or (s.Stoc_initial !=0 and s.Intrari != i.Cantitate)))  
   raiserror ('Modificarea acestei pozitii poate genera necorelatii in stocuri! Iesirile corespunzatoare nu pot fi actualizate!',16,1)  
   
  if exists (                 
  select s.tip_Gestiune, i.Gestiune, i.Gestiune_primitoare, i.Pret_de_stoc, s.pret, i.Cont_corespondent, i.Cont_de_stoc,   
    s.Cont, i.Grupa, i.Cod_intrare, i.Pret_amanunt_predator, i.Pret_cu_amanuntul, s.Pret_cu_amanuntul  from inserted i   
    inner join stocuri s on i.subunitate=s.subunitate and s.cod_gestiune=i.gestiune  
                 and s.cod=i.cod and s.cod_intrare=i.cod_intrare  
    where i.tip not in ('PF','CI') and ((i.pret_de_stoc!=s.pret or i.cont_de_stoc!=s.cont)  
     or (s.Tip_gestiune='A' and (case when i.tip_miscare='I' then round(i.Pret_cu_amanuntul,5)   
                   else round(i.Pret_amanunt_predator,5) end)!=round(s.Pret_cu_amanuntul,5)))  
       
  union all  
  /* tratez TI-urile */  
  select s.tip_Gestiune, i.Gestiune, i.Gestiune_primitoare, i.Pret_de_stoc, s.pret, i.Cont_corespondent, i.Cont_de_stoc, s.Cont, i.Grupa, i.Cod_intrare,   
    i.Pret_amanunt_predator, i.Pret_cu_amanuntul, s.Pret_cu_amanuntul from inserted i   
    inner join stocuri s on i.subunitate=s.subunitate and s.cod_gestiune=Gestiune_primitoare  
                 and s.cod=i.cod  
                 and s.cod_intrare=(case when tip='TE' and grupa<>'' then grupa else i.cod_intrare end)  
    where i.tip ='TE' and ((round(i.pret_de_stoc,5)!=round(s.pret,5) or i.cont_Corespondent !=s.cont)  
      or (s.Tip_gestiune='A' and (case when i.tip_miscare='I' then round(i.Pret_cu_amanuntul,5)  
                    else round(i.Pret_amanunt_predator,5) end)!=round(s.Pret_cu_amanuntul,5)))  
  )      
  raiserror('Pretul sau contul este diferit intre stocuri si document!',16,1)   
   
 end   
   
 --validare cont_tert pe aceasi factura   
 if UPDATE (cont_factura) and 1=0 -- Ghita, 27.04.2012: aceasta validare se va face dinspre triggerul "docFact", ca sa nu depind de ordinea de executie a triggerelor  
  if exists (select 1 from inserted i   
   inner join facturi f on i.Subunitate=f.Subunitate and f.tert=i.Tert and f.Factura=i.Factura  and f.Data=i.Data_facturii   
    and f.Cont_de_tert!=i.Cont_factura and f.Tip=case when i.Tip in ('RM','RP','RQ','RS') then 0x54 else 0x46 end  
   where i.Tip in ('RM','RP','RQ','RS','AP','AS'))  
  begin  
   raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Pe aceasta factura exista deja un alt cont de tert!',16,1)  
  end   
    
 --validare loc de munca pe aceasi factura   
 if UPDATE (Loc_de_munca) and 1=0 -- Ghita, 16.04.2012: nu este necesara o astfel de validare, nu exprima cazul general.  
  if exists   
   (select 1 from inserted i   
   inner join facturi f on i.Subunitate=f.Subunitate and f.tert=i.Tert and f.Factura=i.Factura  and f.Data=i.Data_facturii   
    and f.Loc_de_munca!=i.Loc_de_munca and f.Tip=case when i.Tip in ('RM','RP','RQ','RS') then 0x54 else 0x46 end)  
  begin  
   raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Pe aceeasi factura nu pot fi atasate mai multe locuri de munca!',16,1)  
  end    
    
 --validare data de scadenta pe aceasi factura   
 if UPDATE (Data_scadentei) and 1=0 -- Ghita, 27.04.2012: nu merge bine, nu permite modificarea dinspre doc. sursa!  
  if exists (select 1 from inserted i   
   inner join facturi f on i.Subunitate=f.Subunitate and f.tert=i.Tert and f.Factura=i.Factura  and f.Data=i.Data_facturii   
    and f.Data_scadentei!=i.Data_scadentei and f.Tip=case when i.Tip in ('RM','RP','RQ','RS') then 0x54 else 0x46 end)  
  begin  
   raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Pe aceeasi factura nu pot fi atasate mai multe date de scadenta!',16,1)  
  end     
   
 --validare introducere pozitie iesire negativa fara cod_intrare specificat  
 if 1=0 and exists (select 1 from inserted i -- Ghita, 27.04.2012: nu merge bine, nu tine cont de pret mediu  
   inner join nomencl n on i.Cod=n.Cod and n.Tip!='R' and n.Tip!='S' and i.Tip_miscare='E' and i.Cantitate<0.0001 and isnull(i.Cod_intrare,'')='')  
 begin  
  raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Pentru operare pozitie de iesire cu cantitate negativa(storno) trebuie precizat un cod de intrare!',16,1)  
 end    
 
 if exists (select 1 from inserted i where  not exists 
	(select 1 from doc d where d.Subunitate=i.Subunitate and d.Tip=i.Tip and d.Numar=i.Numar and d.Data=i.Data))
raiserror('nu exista antet',11,1)
end try  
begin catch  
 --Daca exista erori  
 ROLLBACK TRANSACTION  
 set @mesaj = ERROR_MESSAGE()  
 raiserror(@mesaj, 11, 1)  
 RETURN  
end catch  