pragma solidity ^0.4.18;

import "contracts/interfaces/ERC20.sol";
import "contracts/interfaces/InvestorsPool.sol";

contract UnilotToken is ERC20 {
    enum TokenState {
        PRE_ICO,
        ICO_PHASE_1,
        ICO_PHASE_2,
        PRODUCTION
    }

    string public constant symbol = "UNIT";
    string public constant name = "Unilot gaming platform token";
    uint8 public constant decimals = 0;
    uint256 public constant _totalSupply = 100000000; //100 million
    uint256 public constant personalCap = 10000; //0.01%

    //Token price in production stage. Price can change in future.
    uint256 public constant price = 0.025 ether;

    // Owner of this contract
    address public administrator;

    //Token state
    TokenState public state;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    InvestorsPool _investorsPool;

    // Functions with this modifier can only be executed by the owner
    modifier onlyAdministrator() {
        require(msg.sender != administrator);
        _;
    }

    modifier onlyRegisteredInvestors() {
        require(_investorsPool.isCanInvest(msg.sender));
        _;
    }

    function getStatePriceCoeficent()
        public
        pure
        returns (uint8[3] memory)
    {
        return ( [ 10, 8, 5 ] );
    }

    function getCurrentPrice()
        public
        view
        returns (uint currentPrice)
    {
        currentPrice = price;
        uint8[3] memory statePriceCoeficent = getStatePriceCoeficent();

        if ( uint(state) < statePriceCoeficent.length ) {
            currentPrice = price / statePriceCoeficent[uint8(state)];
        }
    }

    // Constructor
    function UnilotToken(InvestorsPool investorsPool)
        public
    {
        administrator = msg.sender;
        state = TokenState.PRE_ICO;
        balances[administrator] = _totalSupply;
        _investorsPool = investorsPool;
    }


    function totalSupply()
        public
        constant
        returns (uint256)
    {
        return _totalSupply;
    }


    // What is the balance of a particular account?
    function balanceOf(address _owner)
        public
        constant
        returns (uint256 balance)
    {
        return balances[_owner];
    }


    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount)
        public
        returns (bool success)
    {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);

            return true;
        } else {
            return false;
        }
    }


    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        public
        returns (bool success)
    {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }


    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }


    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function ()
        public
        payable
        onlyRegisteredInvestors
    {
        uint amount = msg.value/getCurrentPrice();
        uint refund = msg.value - (amount * getCurrentPrice());

        require( amount > 0 );
        require( ( balances[msg.sender] + amount ) <= personalCap );
        require( balances[administrator] >= amount );

        balances[administrator] -= amount;
        balances[msg.sender] += amount;

        if ( refund > 0 ) {
            msg.sender.transfer(refund);
        }
    }
}