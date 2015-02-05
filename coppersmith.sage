def coppersmith_univariate(pol, beta):
    """Howgrave-Graham revisited method
    using with epsilon
    """
    # init
    dd = pol.degree()
    NN = pol.parent().characteristic()

    # checks
    if not 0 < beta <= 1:
        raise ValueError("beta should belongs in (0, 1]")

    if not pol.is_monic():
        raise ArithmeticError("Polynomial must be monic.")
    
    # choose epsilon, m and t
    """ epsilon can be anything?
    if epsilon is <= 1/7 * beta
    then we can use m = ceil(beta^2/delta epsilon)
    otherwise m >= max{ beta^2/delta epsilon, 7beta/delta }
    """
    epsilon = beta / 7
    mm = ceil(beta**2 / (dd * epsilon))
    tt = floor(dd * mm * ((1/beta) - 1)) # t = 0 if beta = 1, rly?

    # change ring of pol and x
    polZ = pol.change_ring(ZZ) # shouldnt it be bb^mm ? => base_ring must be a ring
    x = polZ.parent().gen()
    
    # compute polynomials
    gg = []
    for ii in range(mm):
        for jj in range(dd):
            gg.append(x**jj * NN**(mm - ii) * polZ**ii)
    hh = [] # beta=1 => t=0 => no h_i polynomials
    for ii in range(tt):
        hh.append(x**ii * polZ**mm)
    
    # compute bound X
    XX = ceil(N**((beta**2/dd) - epsilon))
    
    # construct lattice B
    nn = dd * mm + tt
    BB = Matrix(ZZ, nn) # why not use gen_lattice?
    """here sage's implementation uses rectangular matrix
    why???
    """
    for ii in range(nn):
        for jj in range(ii+1):
            # fill gg
            if ii < dd*mm:
                BB[ii, jj] = gg[ii][jj] * XX**jj
            # fill hh
            else:
                BB[ii, jj] = hh[ii][jj]

    # LLL
    BB = BB.LLL()
    
    # Find shortest vector in new basis
    """ Apparently Sage doesn't sort after LLL
    """
    normn = norm(BB[0])
    norm_index = 0

    for ii in range(1, nn):
        if norm(BB[ii]) < normn:
            normn = norm(BB[ii])
            norm_index = ii

    # transform shortest vector in polynomial    
    new_pol = 0
    for ii in range(nn):
        new_pol += x**ii * BB[norm_index, ii] / XX**ii
    
    # factor polynomial
    potential_roots = new_pol.roots() # doesn't find anything...

    # test roots on original pol
    roots = []
    for root in potential_roots:
        result = ZZ(pol(ZZ(root[0])))

        if gcd(NN, result) >= NN**beta:
            roots.append(root[0])

    # no roots found
    return roots
    
# Test on Stereotyped Messages
# (from http://www.sagemath.org/doc/reference/polynomial_rings/sage/rings/polynomial/polynomial_modn_dense_ntl.html#sage.rings.polynomial.polynomial_modn_dense_ntl.small_roots)

Nbits, Kbits = 512, 56
e = 3
p = 2^256 + 2^8 + 2^5 + 2^3 + 1
q = 2^256 + 2^8 + 2^5 + 2^3 + 2^2 + 1
N = p*q
ZmodN = Zmod( N )
K = ZZ.random_element(0, 2^Kbits)
Kdigits = K.digits(2)
M = [0]*Kbits + [1]*(Nbits-Kbits)
for i in range(len(Kdigits)): M[i] = Kdigits[i]

M = ZZ(M, 2)
C = ZmodN(M)^e
P.<x> = PolynomialRing(ZmodN, implementation='NTL')
f = (2^Nbits - 2^Kbits + x)^e - C

print("short root is:", K)
roots = coppersmith_univariate(f, 1)
print("we found:", roots)

# Test on Factoring with High Bits Known
length = 512
hidden = 110
p = next_prime(2^int(round(length/2)))
q = next_prime( round(pi.n()*p) )
N = p*q
qbar = q + ZZ.random_element(0,2^hidden-1)
F.<x> = PolynomialRing(Zmod(N), implementation='NTL')
f = x - qbar
d = f.small_roots(X=2^hidden-1, beta=0.5)[0] # time random
print("test 2")
print("we want to find:", q)
print("we found:", qbar - d)
#moi = coppersmith_univariate(f, 0.5)
#print("et moi:", moi + qbar)
