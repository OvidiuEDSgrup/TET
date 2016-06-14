--begin tran
--set transaction isolation level read uncommitted
--alter table preturi disable trigger all
delete preturi --where Cod_produs='537d6302' 
insert preturi 
select * from tet..preturi
exec yso_xScriuTabela 'preturi','\\asis\IMPORT\ASIS_import_preturi_8 sep 2014.xlsx'

select * from preturi p where p.Cod_produs='537d6302' 
order by p.Data_inferioara desc

select * from mesajeASiS m where m.Destinatar=HOST_ID()
--rollback tran 367:Invalid object name '#preturiXlsDifTmp'.                                                                                                                                                                                                                                                                                                                                                                                                                                                                        