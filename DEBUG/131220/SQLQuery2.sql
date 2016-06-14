execute AS login='TET\dana.capsuc'
declare @p2 xml
set @p2=convert(xml,N'<row numar="9550031_1" data="12/17/2013" tert="RO24273261" dentert="ADP INSTAL SRL (CF/CNP: RO24273261)" contvenituri="472" lm="1VZ_CJ_00" factura="" zilescadenta="0" aviznefacturat="0" tiptva="0" tip="AS"><row cod="AVANS" denumire="CV. AVANS" cantitate="1" pvaluta="1612.90" cotatva="24" sumatva="387.100" subtip="AS"/></row>')
exec wScriuPozdoc @sesiune='E2365BF3CD555',@parXML=@p2
select * from pozdoc p where p.Subunitate='1' and p.Tip='AS' order by p.Data_operarii desc, p.Ora_operarii desc
revert