
/****** Object:  Trigger [dbo].[tr_ValidPozdoc]    Script Date: 03/01/2012 15:29:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--***
ALTER  trigger [dbo].[tr_ValidPozdoc] on [dbo].[pozdoc] for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int,@mesaj varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try	
	if UPDATE(tert) --Verificam consistenta tertilor pe anumite tipuri, la fel va fi pe celelalte campuri
	begin
		if (select min(case when inserted.tip in ('RM','RS','AP','AS') and terti.tert is null then '' else 'corect' end)
		from inserted 
		left outer join terti on inserted.Subunitate=terti.Subunitate and inserted.Tert=terti.tert)=''
			raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Tert neintrodus sau inexistent in catalogul de terti!',16,1)
	end 
	
	if update(cod) --Verificam consistenta codurilor
	begin
		if (select min(case when inserted.Tip NOT in ('RP','RQ') and n.cod is null then '' else 'corect' end)
		from inserted 
		left outer join nomencl n on inserted.cod=n.cod)=''
			raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Cod neintrodus sau inexistent in nomenclator!',16,1)
	end   

	-- de aici am mutat validare loc de munca in tr_Validpozincon
	if UPDATE(gestiune) --se pot citi proprietati pe gestiune
	begin
		declare @userASiS varchar(50) 
		set @userASiS=dbo.fIaUtilizator(null)
		-- mai jos am verificat daca pe pozitile de I/E gestiunile sunt corecte
		if (select min(case when (inserted.Tip_miscare in ('I','E') and gestiuni.Cod_gestiune is null and inserted.Tip not in('PF','AF','CI')) 
			or (inserted.Tip in ('PF','AF','CI') and p.Marca is null)	--in cazul PF....etc in capul gestiune se tine marca=> validam marca
			or (inserted.tip='TE' and g1.Cod_gestiune is null)
			or (inserted.tip in ('PF','DF') and p1.Marca is null)  -- in cazul PF,DF trebuie validata si marca primitoare
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
				where Tip_miscare in ('I','E') and pr.Valoare is null) 
			raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Nu aveti drepturi pe aceasta gestiune!',16,1)
	end
	

	if UPDATE(pret_de_stoc) or UPDATE(cont_de_stoc)
	begin
	--	/*Pentru documentele de iesire vom verifica daca pretul si contul din tabela stocuri 
	--	este egal cu cel al documentului*/
		if exists(
			select 1 from inserted i
			inner join gestiuni g on i.subunitate=g.subunitate and i.gestiune=g.cod_gestiune
			inner join stocuri s on i.subunitate=s.subunitate and s.tip_gestiune=g.tip_gestiune and s.cod_gestiune=i.gestiune and s.cod=i.cod and s.cod_intrare=i.cod_intrare
			where i.tip not in ('PF','CI') and i.tip_miscare='E' and (i.pret_de_stoc!=s.pret or i.cont_de_stoc!=s.cont)
				and (s.Tip_gestiune!='A' or i.Pret_amanunt_predator=s.Pret_cu_amanuntul))
			begin 
				raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Pretul sau contul este diferit intre stocuri si document!',16,1)		
			end 
	end 
	
		--validare cont_tert pe aceasi factura 
	if UPDATE (cont_factura) and 1=0
		if exists 
			(select 1 from inserted i 
			inner join pozdoc p on i.Subunitate=p.Subunitate and p.tert=i.Tert and p.Factura=i.Factura  and p.Cont_factura!=i.Cont_factura and p.Numar_pozitie!=i.Numar_pozitie )
		begin
			raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Pe aceasta factura exista deja un alt cont de tert!',16,1)
		end	
			
	--validare loc de munca pe aceasi factura 
	if UPDATE (Loc_de_munca) and 1=0
		if exists 
			(select 1 from inserted i 
			inner join pozdoc p on i.Subunitate=p.Subunitate and p.tert=i.Tert and p.Factura=i.Factura  and p.Loc_de_munca!=i.Loc_de_munca and p.Numar_pozitie!=i.Numar_pozitie)
		begin
			raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Pe aceasi factura nu pot fi atasate mai multe locuri de munca!',16,1)
		end		
		
	--validare data de scadenta pe aceasi factura	
	if UPDATE (Data_scadentei) and 1=0
		if exists 
			(select 1 from inserted i 
			inner join pozdoc p on i.Subunitate=p.Subunitate and p.tert=i.Tert and p.Factura=i.Factura  and p.Data_scadentei!=i.Data_scadentei and p.Numar_pozitie!=i.Numar_pozitie)
		begin
			raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Pe aceasi factura nu pot fi atasate mai multe date de scadenta!',16,1)
		end			
		

	if UPDATE(cantitate) or 1=1 --UPDATE(gestiune, cod, cod_intrare, TE.grupa) or exists in DELETED
	/* Verificam pentru stocuri*/
	begin
		if exists (select 1 from 
			(select i.subunitate, i.cod, i.gestiune, i.cod_intrare from inserted i where i.Tip_miscare<>'V' and i.jurnal<>'MFX'
				union all 
			select d.subunitate, d.cod, d.gestiune, d.cod_intrare from deleted d where d.Tip_miscare<>'V' and d.Jurnal<>'MFX') p
				inner join gestiuni g on p.subunitate=g.subunitate and p.gestiune=g.cod_gestiune
				left outer join stocuri s on p.subunitate=s.subunitate and s.tip_gestiune=g.tip_gestiune and s.cod_gestiune=p.gestiune 
					and s.cod=p.cod and s.cod_intrare=p.cod_intrare
			group by s.subunitate,s.Tip_gestiune,s.Cod_gestiune,s.Cod,s.Cod_intrare
			having SUM(isnull(s.stoc,0))<-0.00001)
		begin
			raiserror('Eroare operare (pozdoc.tr_ValidPozdoc): Operarea acestui document ar genera stoc negativ!',16,1)
		end
	end
end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	RETURN
end catch

GO
EXEC sp_settriggerorder @triggername=N'[dbo].[tr_ValidPozdoc]', @order=N'Last', @stmttype=N'INSERT'