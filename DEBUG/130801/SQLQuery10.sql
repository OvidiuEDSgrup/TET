SELECT 'drop trigger '+o.name
,* from sys.objects o where o.name like '%valid%' and o.type like 'tr'
drop trigger tr_validConturi
drop trigger tr_ValidAvexcep
drop trigger tr_ValidPozincon
drop trigger tr_validBenret
drop trigger tr_ValidPozNCon
drop trigger tr_ValidConalte
drop trigger tr_ValidConcodih
drop trigger tr_ValidConmed
drop trigger tr_ValidCorectii
drop trigger tr_validRealcom
drop trigger tr_ValidExtinfop
--drop trigger yso_tr_validPozcon
--drop trigger yso_tr_validPozcon
--drop trigger yso_tr_validPozcon
--drop trigger yso_tr_validPozcon
drop trigger tr_validFunctii