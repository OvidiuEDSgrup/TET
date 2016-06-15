--***
create procedure scriuPozincon 
 @Subunitate char(9), @Tip_document char(2), @Numar_document char(13), @Data datetime, 
 @Cont_debitor varchar(40), @Cont_creditor varchar(40), @Suma float, @Valuta char(3), @Curs float, 
 @Suma_valuta float, @Explicatii char(50), @Utilizator char(10), @Numar_pozitie int output, 
 @Loc_de_munca char(9), @Comanda char(40), @Jurnal char(3), 
 @note_receptii bit,  -- Ghita, 30.05.2013: nu mai scriu in pozncon, ci direct in pozincon!
 @indbug varchar(20)=''
as 
begin 

	declare @Data_operarii datetime, @Ora_operarii char(6) 
	set @Data_operarii = convert(datetime, convert(char(10), getdate(), 104), 104) 
	set @Ora_operarii = replace(convert(char(8), getdate(), 114),':','')
	if isnull(@utilizator,'')=''
		set @Utilizator=dbo.fIaUtilizator(null)

	if @indbug is null
		set @indbug=''

	if isnull(@Subunitate, '')=''
		exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Subunitate output

	if abs(@Suma)<0.01 and abs(@Suma_valuta)<0.01
		return

	if 1=0 and @note_receptii=1 -- vezi mai sus!
	begin 
		exec scriuPozncon @Subunitate, @Tip_document, @Numar_document, @Data, @Cont_debitor, 
			@Cont_creditor, @Suma, @Valuta, @Curs, @Suma_valuta, @Explicatii, @Utilizator, 
			@Numar_pozitie output, @Loc_de_munca, @Comanda, '', @Jurnal 
		return
	end 
	
	--set @Numar_pozitie=null --aceasta procedura va da intotdeauna un @numar de pozitie, nu trebuie sa il caute alte proceduri
	-- Ghita, 30.05.2013: dar il poate primi (ex. de la pozplin)!
	if isnull(@Numar_pozitie,0)=0 --is null
	begin
		select @Numar_pozitie=numar_pozitie 
		from pozincon -- caut o pozitie care sa corespunda cu datele trimise
		where subunitate=@Subunitate and tip_document=@Tip_document and numar_document=@Numar_document 
			and data=@Data and cont_debitor=@Cont_debitor and cont_creditor=@Cont_creditor 
			and loc_de_munca=@Loc_de_munca and comanda=@Comanda and valuta=@Valuta
	end
	if isnull(@Numar_pozitie,0)=0 --is null
		set @Numar_pozitie=1+isnull((select max(numar_pozitie) 
		from pozincon -- daca nu am gasit pozitie, caut urmatorul numar 
		where subunitate=@Subunitate and tip_document=@Tip_document and numar_document=@Numar_document 
		and data=@Data), 0)

	if not exists (select 1 from pozincon where subunitate=@Subunitate and tip_document=@Tip_document 
			and numar_document=@Numar_document and data=@Data and cont_debitor=@Cont_debitor 
			and cont_creditor=@Cont_creditor and loc_de_munca=@Loc_de_munca and comanda=@Comanda 
			and valuta=@Valuta and numar_pozitie=@Numar_pozitie) 
	--Inseamna ca vreau sa adaug
		insert into pozincon
			(Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma, 
			Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, 
			Loc_de_munca, Comanda, Jurnal, Indbug) 
			values 
			(@Subunitate, @Tip_document, @Numar_document, @Data, @Cont_debitor, @Cont_creditor, @Suma, 
			@Valuta, @Curs, @Suma_valuta, @Explicatii, @Utilizator, @Data_operarii, @Ora_operarii, @Numar_pozitie, 
			@Loc_de_munca, @Comanda, @Jurnal, @Indbug) 
	else --Inseamna ca vreau sa modific
		update pozincon set suma = suma + @Suma, suma_valuta = suma_valuta + @Suma_valuta, 
			curs = (case when @Valuta<>'' and @Curs<>0 then @Curs else curs end)
			where subunitate=@Subunitate and tip_document=@Tip_document and numar_document=@Numar_document 
			and data=@Data and cont_debitor=@Cont_debitor and cont_creditor=@Cont_creditor 
			and loc_de_munca=@Loc_de_munca and comanda=@Comanda and valuta=@Valuta 
			and numar_pozitie=@Numar_pozitie 
end 
