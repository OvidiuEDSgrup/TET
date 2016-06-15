--***
create procedure scriuPozncon 
 @Subunitate char(9), @Tip char(2), @Numar char(8), @Data datetime, @Cont_debitor varchar(40), @Cont_creditor varchar(40), 
 @Suma float, @Valuta char(3), @Curs float, @Suma_valuta float, @Explicatii char(50), 
 @Utilizator char(10), @Nr_pozitie int output, @Loc_munca char(9), @Comanda char(40), @Tert char(13), @Jurnal char(3) 
as begin

declare @LuatPozDinPar int

if isnull(@Subunitate, '')=''
 exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Subunitate output
if isnull(@Tip, '')=''
 set @Tip='NC'

if abs(@Suma)<0.01 and abs(@Suma_valuta)<0.01
 return

set @LuatPozDinPar=0

if @Nr_pozitie=0
 set @Nr_pozitie=null

if @Nr_pozitie is null
 select @Nr_pozitie=nr_pozitie 
 from pozncon
 where subunitate=@Subunitate and tip=@Tip and numar=@Numar and data=@Data 
 and cont_debitor=@Cont_debitor and cont_creditor=@Cont_creditor and valuta=@Valuta and loc_munca=@Loc_munca and comanda=@Comanda
if @Nr_pozitie is null
begin
 exec luare_date_par 'DO', 'POZITIE', 0, @Nr_pozitie output, ''
 set @Nr_pozitie=@Nr_pozitie+1
 set @LuatPozDinPar=1
/* 
 while exists (select 1 from pozncon where subunitate=@Subunitate and tip=@Tip and numar=@Numar and data=@Data and nr_pozitie=@Nr_pozitie 
  and not (cont_debitor=@Cont_debitor and cont_creditor=@Cont_creditor and valuta=@Valuta and loc_munca=@Loc_munca and comanda=@Comanda))
  set @Nr_pozitie=@Nr_pozitie + 1 
*/
end

while exists (select 1 from pozncon where subunitate=@Subunitate and tip=@Tip and numar=@Numar and data=@Data and nr_pozitie=@Nr_pozitie 
 and not (cont_debitor=@Cont_debitor and cont_creditor=@Cont_creditor and valuta=@Valuta and loc_munca=@Loc_munca and comanda=@Comanda))
 set @Nr_pozitie=@Nr_pozitie + 1 

if not exists (select 1 from pozncon where subunitate=@Subunitate and tip=@Tip and numar=@Numar and data=@Data and nr_pozitie=@Nr_pozitie)
begin
 declare @Data_operarii datetime, @Ora_operarii char(6) 
 set @Data_operarii = convert(datetime, convert(char(10), getdate(), 104), 104) 
 set @Ora_operarii = replace(convert(char(8), getdate(), 114),':','')
 set @Utilizator=dbo.fIaUtilizator(null)
 
 insert into pozncon 
 (Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal) 
 values 
 (@Subunitate, @Tip, @Numar, @Data, @Cont_debitor, @Cont_creditor, 0, @Valuta, @Curs, 0, @Explicatii, @Utilizator, @Data_operarii, @Ora_operarii, @Nr_pozitie, @Loc_munca, @Comanda, @Tert, @Jurnal)
 if @LuatPozDinPar=1
  exec setare_par 'DO', 'POZITIE', 'Ultim nr. pozitie', 0, @Nr_pozitie, ''
end

update pozncon 
set suma = suma + @Suma, suma_valuta = suma_valuta + @Suma_valuta, curs = (case when @Valuta<>'' and @Curs<>0 then @Curs else curs end)
where subunitate=@Subunitate and tip=@Tip and numar=@Numar and data=@Data and nr_pozitie=@Nr_pozitie 
end 
